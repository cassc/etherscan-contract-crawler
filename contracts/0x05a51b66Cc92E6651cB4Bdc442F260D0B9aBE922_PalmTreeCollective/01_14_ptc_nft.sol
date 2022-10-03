// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PalmTreeCollective is ERC721Enumerable, Ownable, ReentrancyGuard {

    // Events
    event Burn(uint256 tokenId, address burner);

    // Constants
    uint256 public constant TOKEN_LIMIT = 1000;
    uint256 public constant PRESALE_MINT_LIMIT = 100;
    uint256 public constant MAX_MINT_QUANTITY = 5;
    uint256 private constant _GIVEAWAY_LIMIT = 100;

    uint256 public mint_price = .1 ether;

    // Addresses
    address payable constant private _PT_WALLET = payable(0x452A89F1316798fDdC9D03f9af38b0586F8142e5);

    // States
    uint256 public sale_state = 3; // 0 = closed, 1 = presale tier 1, 2 = presale tier 2, 3 = sale
    bool public burn_active = false;

    // General
    string public baseURI;
    string public PROVENANCE_HASH = "";

    // Internal state
    // _presale_allowance[address] > 0 | tier 2 eligible
    // _presale_allowance[address] - 1 | remaining tier 1 mints
    mapping(address => uint256) private _presale_allowance;
    mapping(uint256 => address) private _token_id_burners;

    // Random index
    uint256 private _nonce = 0;
    uint256[TOKEN_LIMIT] private _indices;

    constructor() ERC721("PalmTreeCollective", "PTC") {}

    // General
    function _randomMint(address to) private {
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(_nonce, msg.sender, block.difficulty, block.timestamp)));

        _validMint(to, randomIndex);
    }

    function _validMint(address to, uint256 index) private {
        uint256 validIndex = _validateIndex(index);

        _safeMint(to, validIndex);
    }

    function _validateIndex(uint256 index_to_validate) private returns (uint256) {
        uint256 total_size = TOKEN_LIMIT - totalSupply();
        uint256 index = index_to_validate % total_size;
        uint256 value = 0;

        if(_indices[index] != 0) {
            value = _indices[index];
        }
        else {
            value = index;
        }

        if(_indices[total_size - 1] == 0) {
            _indices[index] = total_size - 1;
        }
        else {
            _indices[index] = _indices[total_size - 1];
        }

        _nonce++;

        return value;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function listTokensForOwner(address owner) external view returns (uint256[] memory) {
        uint256 token_count = balanceOf(owner);
        uint256[] memory result = new uint256[](token_count);
        uint256 index;

        for(index = 0; index < token_count; index++) {
            result[index] = tokenOfOwnerByIndex(owner, index);
        }

        return result;
    }

    // Presale eligible
    function isTierTwoPresaleEligible(address minter) external view returns(bool) {
        return _presale_allowance[minter] > 0;
    }

    function isTierOnePresaleEligible(address minter) external view returns(bool) {
        return _presale_allowance[minter] > 1;
    }

    function presaleAllowanceForAddress(address minter) external view returns(uint) {
        return _presale_allowance[minter];
    }

    // Minting
    function mintTokens(address recipient, uint256 num_tokens) external payable nonReentrant {
        require(sale_state != 0, "Sale is closed");
        require(num_tokens > 0 && num_tokens <= MAX_MINT_QUANTITY, "You can only mint 1 to 5 tokens at a time");

        if(sale_state == 3) {
            // Open sale
            require(totalSupply() + num_tokens <= TOKEN_LIMIT, "Palm Tree Collective has sold out");
        }
        else {
            require(totalSupply() + num_tokens <= PRESALE_MINT_LIMIT, "The maximum presale tokens have been minted");

            if(sale_state == 2) {
                // Tier 2 presale
                require(_presale_allowance[recipient] > 0, "You are not eligible to presale mint");
            }
            else if(sale_state == 1) {
                // Tier 1 presale
                require(_presale_allowance[recipient] - num_tokens >= 1, "You cannot mint that many tokens at this time");
                _presale_allowance[recipient] -= num_tokens;
            }
        }

        if(msg.sender != _PT_WALLET) {
            uint256 total_price = mint_price * num_tokens;
            require(msg.value >= total_price, "Ether value sent too low");
        }

        for(uint256 i = 0; i < num_tokens; i++) {
            _randomMint(recipient);
        }
    }

    // Burning
    function burn(uint256 token_id) external {
        require(burn_active, "You cannot burn at this time");
        require(ownerOf(token_id) == msg.sender, "You cannot burn a token you do not own");

        _burn(token_id);
        _token_id_burners[token_id] = msg.sender;

        emit Burn(token_id, msg.sender);
    }

    function burnerOf(uint256 token_id) external view returns (address) {
        return _token_id_burners[token_id];
    }

    // Owner only
    function setProvenanceHash(string calldata provenanceHash) external onlyOwner {
        PROVENANCE_HASH = provenanceHash;
    }

    function editPresaleAllowance(address[] memory addresses, uint256 amount) public onlyOwner {
        for(uint256 i; i < addresses.length; i++){
            _presale_allowance[addresses[i]] = amount;
        }
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function reserveTokens(uint256[] calldata tokens) external onlyOwner {
        require(sale_state == 0, "Sale is not in closed state");
        require(totalSupply() + tokens.length <= _GIVEAWAY_LIMIT, "Exceeded giveaway supply");

        for (uint256 i = 0; i < tokens.length; i++) {
            _validMint(_PT_WALLET, tokens[i]);
        }
    }

    function setMintPrice(uint256 new_mint_price) external onlyOwner {
        mint_price = new_mint_price;
    }

    function setSaleState(uint256 new_state) external onlyOwner {
        sale_state = new_state;
    }

    function toggleBurnState() external onlyOwner {
        burn_active = !burn_active;
    }

    function withdraw() external onlyOwner {
        uint256 full_balance = (address(this).balance * 100) / 100; // 100%
//        uint256 tenPercentOfBalance = (address(this).balance * 10) / 100; // 10.0%

        _PT_WALLET.transfer(full_balance);
    }
}