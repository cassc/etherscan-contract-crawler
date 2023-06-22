// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Metamonz is ERC721Enumerable, Ownable, AccessControl {

    using Strings for uint256;

    // SET MINT PRICES
    uint256 public BATCH_1_PRICE = 0.077 ether;
    uint256 public BATCH_2_PRICE = 0.077 ether;
    uint256 public BATCH_3_PRICE = 0.09 ether;
    
    // NFT AMOUNTS
    uint256 public constant TOTAL_NUMBER_OF_NFTS = 9999;
    uint256 public constant BATCH_1_AMOUNT = 1000;
    uint256 public constant BATCH_2_AMOUNT = 2400;
    uint256 public constant BATCH_3_AMOUNT = 6400;
    uint256 public constant GIVEAWAY_AMOUNT = 199;
    
    // BATCH 2 WHITELISTE
    bool public IS_BATCH_2_WHITELISTE = true;
    mapping(address => bool) private _batch_2_minters;
    
    // NFT AMOUNTS MINTED
    uint256 public BATCH_1_MINTED = 0;
    uint256 public BATCH_2_MINTED = 0;
    uint256 public BATCH_3_MINTED = 0;
    uint256 public GIVEAWAY_MINTED = 0;
    
    // MAX MINT AMOUNTS
    uint256 public BATCH_1_MAX_MINT = 6;
    uint256 public BATCH_2_MAX_MINT = 6;
    uint256 public BATCH_3_MAX_MINT = 9;
    
    
    // OPEN BATCHES
    bool public BATCH_1_OPEN = false;
    bool public BATCH_2_OPEN = false;
    bool public BATCH_3_OPEN = false;
    
    // MAXIMUM NUMBER OF NFTS PER WALLET
    uint256 public MAX_AMOUNT_PER_WALLET = 18;
    
    // BASE TOKEN URIs
    string private _baseTokenURI_fire = "";
    string private _baseTokenURI_water = "";
    string private _baseTokenURI_dark = "";
    string private _baseTokenURI_cyborg = "";
    
    // MAPPING TOKEN_ID TO THE RIGHT BASE DRAGON
    // 1 = FIRE, 2 = WATER, 3 = DARK, 4 = CYBORG
    mapping(uint256 => uint256) private _bases;

    // MODIFIERS
    modifier whenBatch1Open() {
        require (BATCH_1_OPEN, "METAMONZ: mint is not open");
        _;
    }
    
    modifier whenBatch2Open() {
        require (BATCH_2_OPEN, "METAMONZ: mint is not open");
        _;
    }
    
    modifier whenBatch3Open() {
        require (BATCH_3_OPEN, "METAMONZ: mint is not open");
        _;
    }

    modifier batch2Allowed(address account) {
        if(IS_BATCH_2_WHITELISTE == true) {
            require(isBatch2Allowed(account), "METAMONZ: account is not allowed to mint Batch 2");
        }
        _;
    }

    // EVENTS 
    event Batch1Open(address account);
    event Batch2Open(address account);
    event Batch3Open(address account);
    event Giveaway(address account, address to);
    event Batch1PriceSet(address account, uint256 price);
    event Batch2PriceSet(address account, uint256 price);
    event Batch3PriceSet(address account, uint256 price);
    event Batch1MaxMintSet(address account, uint256 max);
    event Batch2MaxMintSet(address account, uint256 max);
    event Batch3MaxMintSet(address account, uint256 max);
    event MaximumPerWalletSet(address account, uint256 max);

    constructor() ERC721("METAMONZ", "METAMONZ") {}

    receive() external payable {}

    // MINT BATCH 1
    // BASE: 1 = FIRE, 2 = WATER, 3 = DARK, 4 = CYBORG
    function mint_batch_1(uint256 num, uint256 base) public payable whenBatch1Open() {
        require(base >= 1 && base <= 4,                                 "METAMONZ: Base must be 1, 2, 3 or 4");
        require(num <= BATCH_1_MAX_MINT,                                "METAMONZ: You can only mint BATCH_1_MAX_MINT METAMONZ");
        require(balanceOf(msg.sender) + num <= MAX_AMOUNT_PER_WALLET,   "METAMONZ: You can only hold MAX_AMOUNT_PER_WALLET METAMONZ per wallet");
        require(BATCH_1_MINTED + num <= BATCH_1_AMOUNT,                 "METAMONZ: Exceeds maximum METAMONZ for Batch 1");
        require(msg.value >= BATCH_1_PRICE * num,                       "METAMONZ: Ether sent is too less");
        
        uint256 supply = totalSupply();
        
        for(uint256 i; i < num; i++) {
            BATCH_1_MINTED += 1;
            
            _bases[supply + i] = base;
            
            _safeMint(msg.sender, supply + i);
        }
    }
    
    // MINT BATCH 2
    // BASE: 1 = FIRE, 2 = WATER, 3 = DARK, 4 = CYBORG
    function mint_batch_2(uint256 num, uint256 base) public payable whenBatch1Open() whenBatch2Open() batch2Allowed(msg.sender) {
        require(base >= 1 && base <= 4,                                 "METAMONZ: Base must be 1, 2, 3 or 4");
        require(num <= BATCH_2_MAX_MINT,                                "METAMONZ: You can only mint BATCH_2_MAX_MINT METAMONZ");
        require(balanceOf(msg.sender) + num <= MAX_AMOUNT_PER_WALLET,   "METAMONZ: You can only hold MAX_AMOUNT_PER_WALLET METAMONZ per wallet");
        require(BATCH_2_MINTED + num <= BATCH_2_AMOUNT,                 "METAMONZ: Exceeds maximum METAMONZ for Batch 2");
        require(msg.value >= BATCH_2_PRICE * num,                       "METAMONZ: Ether sent is too less");
        
        _batch_2_minters[msg.sender] = false;
        
        uint256 supply = totalSupply();
        
        for(uint256 i; i < num; i++) {
            BATCH_2_MINTED += 1;
            
            _bases[supply + i] = base;
            
            _safeMint(msg.sender, supply + i);
        }
    }
    
    // MINT BATCH 3
    // BASE: 1 = FIRE, 2 = WATER, 3 = DARK, 4 = CYBORG
    function mint_batch_3(uint256 num, uint256 base) public payable whenBatch1Open() whenBatch2Open() whenBatch3Open() {
        require(base >= 1 && base <= 4,                                 "METAMONZ: Base must be 1, 2, 3 or 4");
        require(num <= BATCH_3_MAX_MINT,                                "METAMONZ: You can only mint BATCH_3_MAX_MINT METAMONZ");
        require(balanceOf(msg.sender) + num <= MAX_AMOUNT_PER_WALLET,   "METAMONZ: You can only hold MAX_AMOUNT_PER_WALLET METAMONZ per wallet");
        require(BATCH_3_MINTED + num <= BATCH_3_AMOUNT,                 "METAMONZ: Exceeds maximum METAMONZ for Batch 3");
        require(msg.value >= BATCH_3_PRICE * num,                       "METAMONZ: Ether sent is too less");
        
        uint256 supply = totalSupply();
        
        for(uint256 i; i < num; i++) {
            BATCH_3_MINTED += 1;
            
            _bases[supply + i] = base;
            
            _safeMint(msg.sender, supply + i);
        }
    }

    // GIVEAWAY
    // BASE: 1 = FIRE, 2 = WATER, 3 = DARK, 4 = CYBORG
    function giveAway(address _to, uint256 base) external onlyOwner {
        require(base >= 1 && base <= 4,                                 "METAMONZ: Base must be 1, 2, 3 or 4");
        require(GIVEAWAY_MINTED < GIVEAWAY_AMOUNT,                      "METAMONZ: All giveaway NFTs have been minted");
        GIVEAWAY_MINTED += 1;
        uint256 supply = totalSupply();
        
        _bases[supply] = base;
        
        _safeMint(_to, supply);
        
        emit Giveaway(msg.sender, _to);
    }
    
    // SET WHITELIST FOR BATCH 2
    function setBatch2Whitelist(address[] calldata _addresses) external onlyOwner {
        for(uint256 i; i < _addresses.length; i++) {
            _batch_2_minters[_addresses[i]] = true;
        }
    }
    
    // CHECK WHITELISTE
    function isBatch2Allowed(address account) public view returns (bool) {
        return _batch_2_minters[account];
    }
    
    // ENABLE/DISABLE WHITELIST
    function setIsBatch2Whitelist(bool state) public onlyOwner {
        IS_BATCH_2_WHITELISTE = state;
    }
    
    // SET BATCH 1 MINT PRICE
    function setBatch1MintPrice(uint256 price) public onlyOwner {
        BATCH_1_PRICE = price;
        emit Batch1PriceSet(msg.sender, price);
    }
    
    // SET BATCH 2 MINT PRICE
    function setBatch2MintPrice(uint256 price) public onlyOwner {
        BATCH_2_PRICE = price;
        emit Batch2PriceSet(msg.sender, price);
    }
    
    // SET BATCH 3 MINT PRICE
    function setBatch3MintPrice(uint256 price) public onlyOwner {
        BATCH_3_PRICE = price;
        emit Batch3PriceSet(msg.sender, price);
    }
    
    // SET BATCH 1 MAXIMUM MINT AMOUNT
    function setBatch1MaxMint(uint256 max) public onlyOwner {
        BATCH_1_MAX_MINT = max;
        emit Batch1MaxMintSet(msg.sender, max);
    }
    
    // SET BATCH 2 MAXIMUM MINT AMOUNT
    function setBatch2MaxMint(uint256 max) public onlyOwner {
        BATCH_2_MAX_MINT = max;
        emit Batch2MaxMintSet(msg.sender, max);
    }
    
    // SET BATCH 3 MAXIMUM MINT AMOUNT
    function setBatch3MaxMint(uint256 max) public onlyOwner {
        BATCH_3_MAX_MINT = max;
        emit Batch3MaxMintSet(msg.sender, max);
    }
    
    // OPEN BATCH 1 MINT
    function openBatch1() public onlyOwner {
        BATCH_1_OPEN = true;
        emit Batch1Open(msg.sender);
    }
    
    // OPEN BATCH 2 MINT
    function openBatch2() public onlyOwner {
        BATCH_2_OPEN = true;
        emit Batch1Open(msg.sender);
    }
    
    // OPEN BATCH 3 MINT
    function openBatch3() public onlyOwner {
        BATCH_3_OPEN = true;
        emit Batch1Open(msg.sender);
    }
    
    // SET MAXIMUM NFTS AMOUNT PER WALLET
    function setMaximumPerWallet(uint256 max) public onlyOwner {
        MAX_AMOUNT_PER_WALLET = max;
        emit MaximumPerWalletSet(msg.sender, max);
    }

    // GET BASE OF NFT
    // BASE: 1 = FIRE, 2 = WATER, 3 = DARK, 4 = CYBORG
    function getBase(uint256 tokenId) public view returns (uint256) {
        return _bases[tokenId];
    }

    // SET BASE URI
    function setBaseURI(string memory fire, string memory water, string memory dark, string memory cyborg) public onlyOwner {
        _baseTokenURI_fire = fire;
        _baseTokenURI_water = water;
        _baseTokenURI_dark = dark;
        _baseTokenURI_cyborg = cyborg;
    }

    // GET TOKEN URI FOR METADATA
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "METAMONZ: URI query for nonexistent token");

        uint256 base = getBase(tokenId);
        
        string memory baseURI = "";
        
        if (base == 1) {
           baseURI = getBaseURIFire();
        } else if (base == 2) {
           baseURI = getBaseURIWater();
        } else if (base == 3) {
           baseURI = getBaseURIDark();
        } else if (base == 4) {
           baseURI = getBaseURICyborg();
        }

        string memory json = ".json";
        
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
            : '';
    }

    // GET BASE URI FIRE
    function getBaseURIFire() public view returns (string memory) {
        return _baseTokenURI_fire;
    }
    
    // GET BASE URI WATER
    function getBaseURIWater() public view returns (string memory) {
        return _baseTokenURI_water;
    }
    
    // GET BASE URI DARK
    function getBaseURIDark() public view returns (string memory) {
        return _baseTokenURI_dark;
    }
    
    // GET BASE URI CYBORG
    function getBaseURICyborg() public view returns (string memory) {
        return _baseTokenURI_cyborg;
    }
        
    // WITHDRAW    
    function withdraw() external onlyOwner {
        sendEth(owner(), address(this).balance);
    }
    
    // SEND ETHER
    function sendEth(address to, uint amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }
    
    // SUPPORTS INTERFACE
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}