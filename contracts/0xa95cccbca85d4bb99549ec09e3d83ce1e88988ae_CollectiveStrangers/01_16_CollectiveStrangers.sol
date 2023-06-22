//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CollectiveStrangers is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    struct TokenDetails {
        uint256 state;
        uint256 transferAllowTime;
    }

    uint256 public counter;

    uint8 private constant STATE_ONE = 0;
    uint8 private constant STATE_TWO = 1;
    uint8 private constant STATE_THREE = 2;
    string[3] private imageURI;
    string[3] private animationURI;
    uint256 private globalState;
    uint256 private round;
    mapping(uint256 => mapping(uint256 => TokenDetails)) private tokenDetails; // round => tokenId => TokenDetails

    // These could both be constants or immutable if we are comfortable with that
    uint256 public maxTokensPerWallet = 2;
    uint256 public maxTokens;

    uint256 public constant COMMUNITY_SALE_PRICE = 0.05 ether;
    uint256 public maxCommunitySaleTokens;
    bytes32 public communitySaleMerkleRoot;
    bool public isCommunitySaleActive;

    uint256 public maxGiftedTokens;
    uint256 public numGiftedTokens;
    bytes32 public claimListMerkleRoot;
    bool public isClaimActive;

    address public redeemerAddress;

    mapping(address => uint256) public tokenCount;
    mapping(address => bool) public claimed;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier isEOA() {
        require(msg.sender == tx.origin, "Caller is not an EOA");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }

    modifier claimActive() {
        require(isClaimActive, "Token claim is not open");
        _;
    }

    modifier maxTokensPerWalletCheck(uint256 numberOfTokens) {
        require(
            tokenCount[msg.sender] + numberOfTokens <= maxTokensPerWallet,
            "Too many tokens minted"
        );
        _;
    }

    modifier canMintTokens(uint256 numberOfTokens) {
        require(
            counter + numberOfTokens <=
                maxTokens - maxGiftedTokens + numGiftedTokens,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    modifier canGiftTokens(uint256 numberOfTokens) {
        require(
            numGiftedTokens + numberOfTokens <= maxGiftedTokens,
            "Not enough tokens remaining to gift"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens <= msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    constructor(
        uint256 _maxTokens,
        uint256 _maxCommunitySaleTokens,
        uint256 _maxGiftedTokens
    ) ERC721("Collective Strangers", "CSTRNGRS") Ownable() {
        maxTokens = _maxTokens;
        maxCommunitySaleTokens = _maxCommunitySaleTokens;
        maxGiftedTokens = _maxGiftedTokens;
    }

    /**
     * @dev Required to receive royalty payments to the smart contract
     */
    receive() external payable {}

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mintCommunitySale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        communitySaleActive
        canMintTokens(numberOfTokens)
        isCorrectPayment(COMMUNITY_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
        maxTokensPerWalletCheck(numberOfTokens)
        isEOA
    {
        tokenCount[msg.sender] += numberOfTokens;

        for (uint256 i; i < numberOfTokens; i++) {
            counter++;
            _mint(msg.sender, counter);
        }
    }

    function claim(bytes32[] calldata merkleProof)
        external
        claimActive
        canGiftTokens(1)
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
        maxTokensPerWalletCheck(1)
        isEOA
    {
        require(!claimed[msg.sender], "Token already claimed by this wallet");

        tokenCount[msg.sender] += 1;
        claimed[msg.sender] = true;
        numGiftedTokens += 1;

        counter++;
        _mint(msg.sender, counter);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setMaxTokensPerWallet(uint256 _maxTokensPerWallet)
        external
        onlyOwner
    {
        maxTokensPerWallet = _maxTokensPerWallet;
    }

    function setMaxGiftedTokens(uint256 _maxGiftedTokens) external onlyOwner {
        maxGiftedTokens = _maxGiftedTokens;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }

    function setCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = merkleRoot;
    }

    function setIsClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function reserveForGifting(uint256 numToReserve)
        external
        onlyOwner
        canGiftTokens(numToReserve)
    {
        numGiftedTokens += numToReserve;

        for (uint256 i; i < numToReserve; i++) {
            counter++;
            _mint(msg.sender, counter);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setGlobalState(uint256 _state) external onlyOwner {
        require(
            _state == 0 || _state == 1 || _state == 2,
            "Pass a _state that's either 0 or 1 or 2"
        );
        globalState = _state;
    }

    function setRound(uint256 _round) external onlyOwner {
        round = _round;
    }

    function setImageURI(
        string calldata uriOne,
        string calldata uriTwo,
        string calldata uriThree
    ) external onlyOwner {
        imageURI[0] = uriOne;
        imageURI[1] = uriTwo;
        imageURI[2] = uriThree;
    }

    function setAnimationURI(
        string calldata uriOne,
        string calldata uriTwo,
        string calldata uriThree
    ) external onlyOwner {
        animationURI[0] = uriOne;
        animationURI[1] = uriTwo;
        animationURI[2] = uriThree;
    }

    function setRedeemerAddress(address _addr) external onlyOwner {
        redeemerAddress = _addr;
    }

    function redeemAsMintPass(uint256 _tokenId) external returns (bool) {
        require(
            msg.sender == redeemerAddress,
            "Caller is not redeemer address"
        );
        require(globalState == 1, "Global state has not been set to 1");
        require(_exists(_tokenId), "Calling for non-existent token");
        require(
            tokenDetails[round][_tokenId].state != 2,
            "Token already redeemed"
        );
        tokenDetails[round][_tokenId].state = 2;
        tokenDetails[round][_tokenId].transferAllowTime =
            block.timestamp +
            48 *
            3600;
        return true;
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        TokenDetails memory token = tokenDetails[round][tokenId];
        string memory image;
        string memory animation;
        string memory used = "No";
        if (globalState == STATE_ONE) {
            image = imageURI[0];
            animation = animationURI[0];
        } else if (globalState == STATE_THREE) {
            image = imageURI[2];
            animation = animationURI[2];
            if (token.state == STATE_THREE) {
                used = "Yes";
            }
        } else {
            if (token.state == STATE_THREE) {
                image = imageURI[2];
                animation = animationURI[2];
                used = "Yes";
            } else {
                image = imageURI[1];
                animation = animationURI[1];
            }
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Collective Strangers #',
                                tokenId.toString(),
                                '", ',
                                unicode'"description": "The Collective is a members only group of 3,500 strangers, photographers, and those passionate about the stories a photo can tell. The Collective Strangers membership pass acts as your entry to our diverse community, access to member benefits, and our ever evolving product pipeline. Smile 📸",',
                                '"attributes": [{"trait_type": "Used as Mint Pass", "value": "',
                                used,
                                '"}], ',
                                '"image": "',
                                image,
                                '", ',
                                '"animation_url": "',
                                animation,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), (salePrice * 5) / 100);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        TokenDetails memory token = tokenDetails[round][tokenId];
        require(
            block.timestamp > token.transferAllowTime,
            "Token has been used as a mint pass within the past 48 hours"
        );
    }
}