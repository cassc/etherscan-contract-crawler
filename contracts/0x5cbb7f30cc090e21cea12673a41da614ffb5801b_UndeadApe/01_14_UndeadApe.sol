// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract UndeadApe is
    ERC721Enumerable,
    Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;
    
    address proxyRegistryAddress;

    uint256 public whitelistMintPrice = 0.06 ether; 
    uint256 public publicMintPrice = 0.08 ether; 
    uint256 public maxSupply = 5000;
    
    uint256 public whitelistSaleTimeStamp;
    uint256 public publicSaleTimeStamp;
    uint256 public revealTimeStamp;

    string private BASE_URI = "";

    address private founder = 0xebF2Ef5A1eE0dFC75392E8cF6BAa62de28D8E260;
    address private dev = 0xAE77beeda3c1BB43B1cAEaE04815F68e1c07e077;
    address private marketing = 0xD1289b354055D19440020a2C3B27A6167df8c607;
    address private art = 0xD1d48370ddE640a9e58728c235364612352F58a1;
    address private advisor = 0x8e00bc205E913eD242705d6e1F42182e6f9b21f3;
    address private community = 0x1F966f2F84b7adeca70ebe5D10107A71B94D34E3;

    address public whitelistContract1;
    address public whitelistContract2;
    address public whitelistContract3;

    mapping(address => bool) public tier1Whitelist;
    mapping(address => bool) public tier2Whitelist;

    uint256 public tier1Qty = 10;
    uint256 public tier2Qty = 3;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 whitelistSaleStart,
        address proxyRegistryAddress_,
        address whitelistContract1_,
        address whitelistContract2_,
        address whitelistContract3_
    ) ERC721(name, symbol) {
        maxSupply = maxNftSupply;
        whitelistSaleTimeStamp = whitelistSaleStart;
        publicSaleTimeStamp = whitelistSaleStart + (43200);
        revealTimeStamp = whitelistSaleStart + (86400 * 3);
        proxyRegistryAddress = proxyRegistryAddress_;
        whitelistContract1 = whitelistContract1_;
        whitelistContract2 = whitelistContract2_;
        whitelistContract3 = whitelistContract3_;
    }

    function setTierQtys(uint256 _qty1, uint256 _qty2) external onlyOwner {
        tier1Qty = _qty1;
        tier2Qty = _qty2;
    }

    function addToTier1Whitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            tier1Whitelist[addresses[i]] = true;
        }
    }

    function addToTier2Whitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            tier2Whitelist[addresses[i]] = true;
        }
    }

    function whitelistQuantity(address _add) public view returns (uint256) {
        uint256 qty = tier1Whitelist[_add] ? tier1Qty : (tier2Whitelist[_add] ? tier2Qty : 0);
        if (
            IERC721(whitelistContract1).balanceOf(_add) > 0 ||
            IERC721(whitelistContract2).balanceOf(_add) > 0 ||
            IERC721(whitelistContract3).balanceOf(_add) > 0
        ) {
            qty = qty > tier2Qty ? qty : tier2Qty;
        }
        return qty;
    }

    function setWhitelistContracts(address whitelistContract1_, address whitelistContract2_, address whitelistContract3_) external onlyOwner {
        whitelistContract1 = whitelistContract1_;
        whitelistContract2 = whitelistContract2_;
        whitelistContract3 = whitelistContract3_;
    }

    function setWhitelistSaleTimestamp(uint256 timeStamp) external onlyOwner {
        whitelistSaleTimeStamp = timeStamp;
    }

    function setPublicSaleTimestamp(uint256 timeStamp) external onlyOwner {
        publicSaleTimeStamp = timeStamp;
    }

    function setRevealTimestamp(uint256 timeStamp) external onlyOwner {
        revealTimeStamp = timeStamp;
    }

    function setWhitelistSaleMintPrice(uint256 price) external onlyOwner {
        whitelistMintPrice = price;
    }

    function setPublicSaleMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }

    function mint(uint256 numberOfTokens) public payable {
        uint256 whitelistQty = whitelistQuantity(msg.sender);
        require(
            block.timestamp >= publicSaleTimeStamp ||  
            (block.timestamp >= whitelistSaleTimeStamp && balanceOf(msg.sender).add(numberOfTokens) <= whitelistQty), 
            "Either sale is not active or you are not whitelisted to mint these many tokens");
        require(numberOfTokens <= 20, 'Cannot mint more than 20 tokens at a time');
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "Purchase would exceed max supply"
        );
        uint256 mintPrice = whitelistQty > 0 ? whitelistMintPrice : publicMintPrice;
        require(
            mintPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < maxSupply) {
                _mint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(founder).transfer(balance.mul(40).div(100));
        payable(dev).transfer(balance.mul(10).div(100));
        payable(marketing).transfer(balance.mul(20).div(100));
        payable(art).transfer(balance.mul(10).div(100));
        payable(advisor).transfer(balance.mul(25).div(1000));
        payable(community).transfer(balance.mul(175).div(1000));
    }

    function reserve(uint256 num, address _to) external onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 1; i <= num; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return block.timestamp >= revealTimeStamp 
        ? string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json")) 
        : contractURI();
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmPuiaEiiUZX6CqKeXqC5trJg4xq9pN69qn4w5mvFKbAQo";
    }
}