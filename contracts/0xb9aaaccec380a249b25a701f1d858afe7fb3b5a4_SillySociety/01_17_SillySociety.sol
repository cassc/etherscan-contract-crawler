// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "hardhat/console.sol";
import "./Presale.sol";
import "./Whitelist.sol";
import "./OgSale.sol";
import "./OgWhitelist.sol";
import "./WithdrawSilly.sol";
import "./PublicSale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract SillySociety is 
    ERC721AQueryable, 
    Ownable, 
    ReentrancyGuard, 
    Presale,
    Whitelist,
    OgSale,
    OgWhitelist,
    PublicSale,
    WithdrawSilly
    {

    using Strings for uint256;

    // Supply Information
    uint256 public constant OG_SUPPLY = 200;
    uint256 public constant TOTAL_SUPPLY = 3333;
    
    // Max Mint Per Tx
    uint256 public constant MINT = 2;
    uint256 public constant MAX_ADDRESS = 2;

    // Mint Price
    uint256 public constant PUBLIC_PRICE = 0.09 ether;
    uint256 public constant WHITELIST_PRICE = 0.07 ether;
    uint256 public constant OG_PRICE = 0.05 ether;

    constructor(bool _paused, 
     uint256 _publicStart, 
     uint256 _ogSaleStart, 
     uint256 _ogSaleEnd, 
     uint256 _presaleStart,
     uint256 _presaleEnd,
     bytes32 _OgWhitelist,
     bytes32 _Whitelist) ERC721A ("SillySociety", "SSOC") 
     PublicSale(_publicStart) 
     OgSale(_ogSaleStart, _ogSaleEnd)
     Presale(_presaleStart, _presaleEnd)
     OgWhitelist(_OgWhitelist)
     Whitelist(_Whitelist) {
        paused = _paused;
    } 

    // Mapping owner address to address data
    mapping(address => uint256) private addressData;
    
    //Pricing
    function getPrice() public view returns (uint256) {
        if(isPresaleActivated()) { return WHITELIST_PRICE; }
        if(isOgSaleActivated()) { return OG_PRICE; }
        return PUBLIC_PRICE;
    }

    //Mint Compliance
    modifier mintCompliance (uint256 _mintAmount) {
        require(!paused, "Paused!");
        require(addressData[msg.sender] + _mintAmount <= MAX_ADDRESS, "Wallet Maxed");
        require(_mintAmount <= MINT, "Max Mint Exceeded!");
        require(msg.value >= getPrice() * _mintAmount, "Insufficient Funds!");
        require(totalSupply() + _mintAmount <= TOTAL_SUPPLY, "Supply Maxed!");
        _;
    }

    // WhitelistMint
    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) 
        public 
        payable
        isPresaleActive
        isYouAreWhitelisted(_merkleProof)
        mintCompliance(_mintAmount)
    {
        addressData[msg.sender]  += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    //OGMint
    function ogMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable isOgSaleActive isYouAreOgWhitelisted(_merkleProof) mintCompliance(_mintAmount)
    {
        require(totalSupplyOgSale + _mintAmount <= OG_SUPPLY, "OG Maxed!");
        addressData[msg.sender] += _mintAmount;
        totalSupplyOgSale += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    //PublicMint
    function publicMint (uint256 _mintAmount) public payable isPublicSaleActive mintCompliance(_mintAmount) {
        addressData[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // (Marketing Purposes)
    function give(address receivers, uint256 _mintAmount) external onlyOwner nonReentrant {
        require(!paused, "Paused!");
        require(totalSupply() + _mintAmount <= TOTAL_SUPPLY, "Supply Maxed!");
        _safeMint(receivers, _mintAmount);
    }

    // Functions ETC
    bool public paused;
    function setPaused(bool _paused) external onlyOwner nonReentrant{
        paused = _paused;
    }

    string private baseURI;
    function setBaseURI (string memory _baseUri) external onlyOwner nonReentrant{
        baseURI = _baseUri;
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "Token doesn't exist!");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
    }
}