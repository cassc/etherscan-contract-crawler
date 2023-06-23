// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface AnimetasContract {
    function walletOfOwner(address owner) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface AvatrackContract {
    function walletOfOwner(address owner) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function giveawayBatch(address[] memory accounts, uint256[] memory animetas_tokens_ids_to_mint) external;
    function giveaway(address _to, uint256 animetas_token_id) external;
    function getPrice() external view returns (uint256);
    function getDiscountPrice() external view returns (uint256);
    function TOTAL_NUMBER_OF_AVATRACKS() external view returns (uint256);
    function minted_avatracks() external view returns (uint256);
    function getLolabsSplitter() view external returns (address);
}


contract Hovercars is ERC721Enumerable, ReentrancyGuard, Ownable, AccessControl {

    using SafeMath for uint256;
    using Strings for uint256;

    bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
    uint256 public constant TOTAL_NUMBER_OF_HOVERCARS = 10101;

    uint256 public claimed_hovercars = 0;

    mapping(uint256 => bool) private _animetas_claimed_tokens;

    bool public paused_mint = true;

    AnimetasContract private animetas;
    address private animetas_contract_address;
    AvatrackContract private avatracks;
    uint256 private avatracks_price;
    uint256 private avatracks_discount_price;
    address private avatrack_contract_address;
    string private _base_uri;
    address lolabs_splitter;


    modifier whenMintNotPaused() {
        require(!paused_mint, "Hovercars: mint is paused");
        _;
    }

    modifier whenSenderIsAnimetasTokenOwner(uint256 animetas_token_id) {
        require(accountIsAnimetasTokenOwner(msg.sender, animetas_token_id), "Hovercars: Animetas token is not owned by the sender.");
        _;
    }

    event MintPaused(address account);

    event MintUnpaused(address account);

    event GiveawayPerformed(address account, uint256 animetas_token_id);

    event ClaimPerformed(address account, uint256 animetas_token_id);

    constructor(
        string memory uri_,
        address lolabs_team,
        address animetas_contract,
        address avatracks_contract,
        address splitter)
    ERC721("HovercarsAnimetas", "HOVER")
    Ownable()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, lolabs_team);

        _setupRole(WHITE_LIST_ROLE, msg.sender);
        _setupRole(WHITE_LIST_ROLE, lolabs_team);

        animetas = AnimetasContract(animetas_contract);
        animetas_contract_address = animetas_contract;
        avatracks = AvatrackContract(avatracks_contract);
        avatrack_contract_address = avatracks_contract;
        avatracks_price = avatracks.getPrice();
        avatracks_discount_price = avatracks.getDiscountPrice();
        _base_uri = uri_;
        lolabs_splitter = splitter;

    }

    function tokenURI(uint256 token_id) override public view returns (string memory) {
        require(_exists(token_id), "Hovercars: cannot display non existing token");

        string memory baseURI = getBaseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, token_id.toString()))
        : '';
    }

    function claim(uint256 animetas_token_id) public nonReentrant whenMintNotPaused() whenSenderIsAnimetasTokenOwner(animetas_token_id) {
        require(claimed_hovercars < TOTAL_NUMBER_OF_HOVERCARS, "Hovercars: Exceeds maximum Hovercars supply");
        require(_animetas_claimed_tokens[animetas_token_id] == false, "Hovercars: Animetas token was already claimed");
        require(msg.sender == tx.origin, "Hovercars: contracts cannot claim");

        _lfg(msg.sender, animetas_token_id);
        emit ClaimPerformed(msg.sender, animetas_token_id);
    }

    function claimBatch(uint256[] memory animetas_tokens_ids_to_claim) public nonReentrant whenMintNotPaused() {
        _claimBatch(animetas_tokens_ids_to_claim);
    }

    function claimAndMintBatch(
        uint256[] memory animetas_tokens_ids_to_claim,
        uint256[] memory animetas_tokens_ids_to_mint,
        address[] memory accounts) public payable nonReentrant whenMintNotPaused() {
        uint256 num = animetas_tokens_ids_to_mint.length;

        require(160 >= num, "Avatracks: Batch size must be less than 160");
        require(160 >= animetas_tokens_ids_to_claim.length, "Hovercars: Batch size must be less than 160");

        if (num < 5) {
            require(msg.value >= num * avatracks_price, "Avatracks: Ether sent is less than price * tokens_count");
        } else {
            require(msg.value >= num * avatracks_discount_price, "Avatracks: Mint batch more than 5 Animetracks: Ether sent is less than discount price * tokens_count");
        }

        avatracks.giveawayBatch(accounts, animetas_tokens_ids_to_mint);
        _claimBatch(animetas_tokens_ids_to_claim);
    }

    function _claimBatch(uint256[] memory animetas_tokens_ids_to_claim) internal whenMintNotPaused() {
        require(160 >= animetas_tokens_ids_to_claim.length, "Hovercars: Batch size must be less than 160");

        require(claimed_hovercars + animetas_tokens_ids_to_claim.length <= TOTAL_NUMBER_OF_HOVERCARS, "Hovercars: Exceeds maximum Hovercars supply");
        require(msg.sender == tx.origin, "Hovercars: contracts cannot claim");

        for (uint256 i; i < animetas_tokens_ids_to_claim.length; i++) {
            require(accountIsAnimetasTokenOwner(msg.sender, animetas_tokens_ids_to_claim[i]), "Hovercars: Animetas token is not owned by the sender.");
            require(_animetas_claimed_tokens[animetas_tokens_ids_to_claim[i]] == false, "Hovercars: Animetas token was already claimed");
            _lfg(msg.sender, animetas_tokens_ids_to_claim[i]);
            emit ClaimPerformed(msg.sender, animetas_tokens_ids_to_claim[i]);
        }
    }

    function giveaway(address _to, uint256 animetas_token_id) external onlyRole(WHITE_LIST_ROLE) {
        require(_animetas_claimed_tokens[animetas_token_id] == false, "Hovercars: Animetas token was already claimed");
        require(accountIsAnimetasTokenOwner(_to, animetas_token_id), "Hovercars: Account is not the owner of the given animetas");

        _lfg(_to, animetas_token_id);
        emit GiveawayPerformed(_to, animetas_token_id);
    }

    function giveawayBatch(address[] memory accounts, uint256[] memory animetas_tokens_ids_to_claim) external onlyRole(WHITE_LIST_ROLE) {
        for (uint256 i; i < animetas_tokens_ids_to_claim.length; i++) {
            require(!_animetas_claimed_tokens[animetas_tokens_ids_to_claim[i]], "Hovercars: Animetas token was already claimed");
            require(accountIsAnimetasTokenOwner(accounts[i], animetas_tokens_ids_to_claim[i]), "Hovercars: Account is not the owner of the given animetas");
            _lfg(accounts[i], animetas_tokens_ids_to_claim[i]);
            emit GiveawayPerformed(accounts[i], animetas_tokens_ids_to_claim[i]);
        }
    }

    function cleanup(address[] memory accounts, uint256[] memory animetas_tokens_ids_to_claim) external onlyRole(WHITE_LIST_ROLE) {
        require(paused_mint, "Hovercars: can cleanup only when mint is paused");

        for (uint256 i; i < animetas_tokens_ids_to_claim.length; i++) {
            require(!_animetas_claimed_tokens[animetas_tokens_ids_to_claim[i]], "Hovercars: Animetas token was already claimed");
            _lfg(accounts[i], animetas_tokens_ids_to_claim[i]);
            emit GiveawayPerformed(accounts[i], animetas_tokens_ids_to_claim[i]);
        }
    }

    function _lfg(address _to, uint256 animetas_token_id) internal {
        claimed_hovercars = claimed_hovercars + 1;
        _animetas_claimed_tokens[animetas_token_id] = true;
        _safeMint(_to, animetas_token_id);
    }

    function accountIsAnimetasTokenOwner(address account, uint256 animetas_token_id) view private returns (bool) {
        return animetas.ownerOf(animetas_token_id) == account;
    }

    function pauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = true;
        emit MintPaused(msg.sender);
    }

    function unpauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = false;
        emit MintUnpaused(msg.sender);
    }

    function updateAnimetasAddress(address _animetas) public onlyRole(WHITE_LIST_ROLE) {
        animetas = AnimetasContract(_animetas);
        animetas_contract_address = _animetas;
    }

    function getAnimetasAddress() view public returns (address) {
        return animetas_contract_address;
    }

    function updateAvatracksAddress(address _avatrack) public onlyRole(WHITE_LIST_ROLE) {
        avatracks = AvatrackContract(_avatrack);
        avatrack_contract_address = _avatrack;
        avatracks_price = avatracks.getPrice();
        avatracks_discount_price = avatracks.getDiscountPrice();
    }

    function getAvatracksAddress() view public returns (address) {
        return avatrack_contract_address;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 token_count = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](token_count);
        for (uint256 i; i < token_count; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function unclaimedTokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory animetas_tokens_ids = animetas.walletOfOwner(_owner);
        uint256 hovercars_token_count = balanceOf(_owner);
        uint256[] memory result = new uint256[](animetas_tokens_ids.length - hovercars_token_count);

        uint j;
        for (uint256 i; i < animetas_tokens_ids.length; i++) {
            if (!_animetas_claimed_tokens[animetas_tokens_ids[i]]) {
                result[j] = animetas_tokens_ids[i];
                j++;
            }
        }
        return result;
    }

    function isAnimetasTokenClaimed(uint256 animetas_token_id) public view returns (bool) {
        require(animetas_token_id >= 0 && animetas_token_id < 10101, "Hovercars: Token ID invalid");
        return _animetas_claimed_tokens[animetas_token_id];
    }

    function setBaseURI(string memory new_uri) public onlyRole(WHITE_LIST_ROLE) {
        _base_uri = new_uri;
    }

    function getBaseURI() public view returns (string memory) {
        return _base_uri;
    }

    function withdrawAmountToSplitter(uint256 amount) public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Hovercars: withdraw amount call without balance");
        require(_balance - amount >= 0, "Hovercars: withdraw amount call with more than the balance");
        require(payable(lolabs_splitter).send(amount), "Hovercars: FAILED withdraw amount call");
    }

    function withdrawAllToSplitter() public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Hovercars: withdraw all call without balance");
        require(payable(lolabs_splitter).send(_balance), "Hovercars: FAILED withdraw all call");
    }

    function updateLolaSplitterAddress(address _lolabs_splitter) public onlyRole(WHITE_LIST_ROLE) {
        lolabs_splitter = _lolabs_splitter;
    }

    function getLolabsSplitter() view public onlyRole(WHITE_LIST_ROLE) returns (address splitter) {
        return lolabs_splitter;
    }

    function supportsInterface(bytes4 interface_id) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interface_id);
    }

receive() external payable {}

fallback() external payable {}

}