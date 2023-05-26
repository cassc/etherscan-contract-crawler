//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NineSeals is ERC721,Ownable,ReentrancyGuard{

    using SafeMath for uint256;

    uint64 public constant DEFAULT_MAX_BATCH_SIZE = 5;
    uint64 public constant DEFAULT_COLLECTION_SIZE = 10000;

    uint8 private constant SALE_STATUS_NOT_STARTED = 0;
    uint8 private constant SALE_STATUS_ALLOWLIST = 1;
    uint8 private constant SALE_STATUS_PUBLIC = 2;
    uint8 private constant SALE_STATUS_DONE = 3;
    uint8 private constant SALE_STATUS_PAUSED = 4;

    bool private _mintPaused;

    uint64 private _tokenCounter;

    uint64 private _totalAllowedTokens;

    string private _baseTokenURI;

    struct SaleConfig {
        uint16 maxBatchSize;
        uint32 saleKey;
        uint32 saleStartTime;
        uint256 salePrice;        
    }

    SaleConfig public allowlistSaleConfig;

    SaleConfig public publicSaleConfig;

    struct Mintoor {  
        uint128 tokenBalance;  
        uint128 maxAllowlistTokens; 
        uint128 allowlistBalance; 
        uint128 maxPublicSaleTokens;
    }

    mapping(address => Mintoor) public mintoors;
    
    constructor( 
        string memory name, 
        string memory symbol
    ) ERC721(name, symbol) ReentrancyGuard(){
        _tokenCounter = 1;
        _totalAllowedTokens = DEFAULT_COLLECTION_SIZE;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Mint: Owner
    function ownerMint(uint256 quantity) external onlyOwner {
        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenCounter);
            _tokenCounter++;
        }

        mintoors[msg.sender].tokenBalance += uint128(quantity);
    }

    // Mint: Allowlist
    function allowlistMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = allowlistSaleConfig;        
        uint256 salePrice = uint256(config.salePrice);
        Mintoor memory mintoor = mintoors[msg.sender];
        
        require(!isMintPaused(), "mint is paused");
        require(isAllowlistSaleOn(), "allowlist sale has not begun yet");
        require(mintoor.maxAllowlistTokens > 0, "not eligible for allowlist mint");
        require(totalSupply() + quantity <= _totalAllowedTokens, "reached max supply");
        require(quantity <= allowlistTokensRemaining(msg.sender), "you have exceeded the max number of allowlist tokens you can mint");
        require(msg.value >= salePrice.mul(quantity), "not enough ether to complete purchase.");

        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenCounter);
            _tokenCounter++;
        }

        mintoors[msg.sender].tokenBalance += uint128(quantity);
        mintoors[msg.sender].allowlistBalance += uint128(quantity);
    }

    // Mint: Public
    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) external payable callerIsUser {
        SaleConfig memory config = publicSaleConfig;
        uint256 saleKey = uint256(config.saleKey);
        uint256 salePrice = uint256(config.salePrice);
        
        require(saleKey == callerPublicSaleKey, "called with incorrect public sale key");
        require(!isMintPaused(), "mint is paused");
        require(isPublicSaleOn(), "public sale has not begun yet");
        require(totalSupply() + quantity <= _totalAllowedTokens, "reached max supply");
        require(quantity <= publicSaleTokensRemaining(msg.sender), "you have exceeded the max number of tokens you can mint");
        require(msg.value >= salePrice.mul(quantity), "not enough ether to complete purchase.");

        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenCounter);
            _tokenCounter++;
        }

        mintoors[msg.sender].tokenBalance += uint128(quantity);
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            mintoors[addresses[i]].maxAllowlistTokens = uint128(numSlots[i]);
        }
    }

    function updateMaxMints(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            mintoors[addresses[i]].maxPublicSaleTokens = uint128(numSlots[i]);
        }
    }

    function initializeAllowlistSale(uint16 maxBatchSize, uint256 salePrice, uint32 saleStartTime) external onlyOwner {
        allowlistSaleConfig.maxBatchSize = maxBatchSize;
        allowlistSaleConfig.saleStartTime = saleStartTime;
        allowlistSaleConfig.salePrice = salePrice;
    }

    function initializePublicSale(uint16 maxBatchSize, uint256 salePrice, uint32 saleStartTime, uint32 saleKey) external onlyOwner {
        publicSaleConfig.maxBatchSize = maxBatchSize;
        publicSaleConfig.saleKey = saleKey;
        publicSaleConfig.saleStartTime = saleStartTime;
        publicSaleConfig.salePrice = salePrice;
    }

    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        require(_collectionSize >= totalSupply(), "cannot make collection size smaller than supply");
        _totalAllowedTokens = uint64(_collectionSize);
    }

    function totalSupply() public view returns (uint256) {
        return (_tokenCounter - 1);
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function collectionSize() public view returns (uint256) {
        return _totalAllowedTokens;
    }
    
    function numberMinted(address owner) public view returns (uint256) {
        return uint256(mintoors[owner].tokenBalance);
    }

    function maxMintableTokens(address owner) public view returns (uint256) {
        return allowlistSlots(owner) + publicSaleSlots(owner);
    }

    function publicSaleSlots(address owner) public view returns (uint256) {
        Mintoor memory mintoor = mintoors[owner];
        return mintoor.maxPublicSaleTokens != 0 ? uint256(mintoor.maxPublicSaleTokens) : uint256(DEFAULT_MAX_BATCH_SIZE);
    }

    function publicSaleTokensRemaining(address owner) public view returns (uint256) {
        return maxMintableTokens(owner) - numberMinted(owner);
    }

    function allowlistSlots(address owner) public view returns (uint256) {
        return uint256(mintoors[owner].maxAllowlistTokens);
    }

    function allowlistTokensRemaining(address owner) public view returns (uint256) {
        Mintoor memory mintoor = mintoors[owner];
        return uint256(mintoor.maxAllowlistTokens) - uint256(mintoor.allowlistBalance);
    }

    function getAllowlistSaleDuration() public view returns (uint256) {
        SaleConfig memory config = allowlistSaleConfig; 
        return block.timestamp - config.saleStartTime;
    }

    function getSaleStatus() public view returns (uint8) {
        if (isSaleClosed()) {
            return SALE_STATUS_DONE;
        } else if (isMintPaused()) {
            return SALE_STATUS_PAUSED;
        } else if (isPublicSaleOn()) {
            return SALE_STATUS_PUBLIC;
        } else if (isAllowlistSaleOn()) {
            return SALE_STATUS_ALLOWLIST;
        } else {
            return SALE_STATUS_NOT_STARTED;
        }
    }

    function isAllowlistSaleOn() public view returns (bool) {
        SaleConfig memory config = allowlistSaleConfig; 
        return !isPublicSaleOn() && config.saleStartTime > 0 && block.timestamp >= config.saleStartTime;
    }

    function isPublicSaleOn() public view returns (bool) {
        SaleConfig memory config = publicSaleConfig; 
        return config.saleStartTime > 0 && block.timestamp >= config.saleStartTime;
    }

    function isSaleClosed() public view returns (bool) {
        return totalSupply() >= collectionSize();
    }

    function isMintPaused() public view returns (bool) {
        return _mintPaused;
    }

    function pauseMint(bool isPaused) external onlyOwner {
        _mintPaused = isPaused;
    }

    function getMintPrice() public view returns (uint256) {
        if (isPublicSaleOn()) {
           return publicSaleConfig.salePrice;
        } else if (isAllowlistSaleOn()) {
            return allowlistSaleConfig.salePrice;
        } else {
            return 0;
        }
    }

    function getUserConfig(address owner) public view returns (uint256 userAllowlistSlots, uint256 userAllowlistRemaining, uint256 userPublicSlots, uint256 userPublicRemaining, uint256 userTokenBalance) {
        uint256 _allowlistSlots = allowlistSlots(owner);
        uint256 _allowlistRemaining= allowlistTokensRemaining(owner);
        uint256 _publicSlots = maxMintableTokens(owner);
        uint256 _publicRemaining =  publicSaleTokensRemaining(owner);
        uint256 _tokenBalance = numberMinted(owner);

        return (_allowlistSlots, _allowlistRemaining, _publicSlots, _publicRemaining, _tokenBalance);
    }
}