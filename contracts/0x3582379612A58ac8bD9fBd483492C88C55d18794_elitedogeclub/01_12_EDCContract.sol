// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract elitedogeclub is ERC721, ERC721Burnable, Ownable {
    
    using Strings for uint256;
    
    bool public isSale = false;
    bool public isPresale = false;
    bool public isWhitelist = false;
    uint256 public currentToken = 1;
    uint256 public presaleSupply = 17000;
    uint256 public saleSupply = 17000;
    uint256 public maxSupply = 100000;
    uint256 public price = 0.01 ether;
    uint256 public presaleMax = 25;
    uint256 public saleMax = 500;
    uint256 public transMax = 200;
    string public metaUri = "https://www.elitedogeclub.io/tokens/";
    mapping(address => bool) public whitelist;
    
    constructor() ERC721("Elite Doge Club", "EDC") {}
    
    // Mint Functions - Public

    function mint(uint256 quantity) public payable {
        require(isSale, "Public Sale is Not Active");
        require(quantity <= transMax, "Max 200 Are Allowed Per Transaction" );
        require((currentToken - 1 + quantity) <= saleSupply, "Quantity Exceeds Tokens Available");
        require((balanceOf(msg.sender) + quantity) <= saleMax, "Max 500 Are Allowed Per Wallet" );
        require((price * quantity) <= msg.value, "Ether Amount Sent Is Incorrect");
        _mintTokens(quantity);
    }
    
     function presaleMint(uint256 quantity) public payable {
        require(isPresale, "Presale is Not Active");
        if (isWhitelist) {
            require(whitelist[(msg.sender)] == true, "You Are Not Whitelisted for Presale");
        }
        require((balanceOf(msg.sender) + quantity) <= presaleMax, "Max 25 Are Allowed Per Wallet in Presale" );
        require((currentToken - 1 + quantity) <= presaleSupply, "Quantity Exceeds Tokens Available in Presale");
        require((price * quantity) <= msg.value, "Ether amount sent is incorrect");
        _mintTokens(quantity);
     }
    
    function ownerMint(address[] memory addresses) external onlyOwner {
        require((currentToken - 1 + addresses.length) <= saleSupply, "Mint Quantity Exceeds Tokens Available");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], currentToken);
            currentToken = currentToken + 1;
        }
    }

    // Token URL and Supply Functions - Public

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString(), ".json"));
    }
    
    function totalSupply() external view returns (uint256) {
        return (currentToken - 1);
    }
    
    // Setter Functions - onlyOwner

    function triggerSale() public onlyOwner {
        isSale = !isSale;
    }

    function triggerPresale() public onlyOwner {
        isPresale = !isPresale;
    }
    
    function triggerWhitelist() public onlyOwner {
        isWhitelist = !isWhitelist;
    }

    function setMetaURI(string memory newURI) external onlyOwner {
        metaUri = newURI;
    }
    
    function setSupply(uint256 newSupply) external onlyOwner {
        require(newSupply <= maxSupply, "You Cannot Set Supply More Than 100000");
        saleSupply = newSupply;
    }
    
    // Whitelist Functions - onlyOwner
    
    function addToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++){
            whitelist[addresses[i]] = true;
    }}
    
    function removeFromWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length ; i++){
            whitelist[addresses[i]] = false;
    }}

    // Withdraw Function - onlyOwner

    function withdraw() external onlyOwner {
        uint256 halfAmount = address(this).balance*50/100;
        require(payable(0x360867dC840840676c00b0456B29480cfF334D0E).send(halfAmount));
        require(payable(0xFa6c9b79d673c7C06a5E44f3733ceab79D9711A4).send(halfAmount));
    }

    // Internal Functions
    
    function _mintTokens(uint256 quantity) internal {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return metaUri;
    }
    
}