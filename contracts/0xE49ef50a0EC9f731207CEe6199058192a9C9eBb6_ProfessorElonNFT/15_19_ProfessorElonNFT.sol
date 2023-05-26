// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

/**
 * @title ProfessorElonNFT
 * ProfessorElonNFT - a contract for Professor Elon NFTs
 */
contract ProfessorElonNFT is ERC721Tradable {
    using SafeMath for uint256;
    address constant WALLET1 = 0xc4eeB8020e539C70Ecbd6464F7dB3Fe61de91986;
    address constant WALLET2 = 0x60EAbA940B9d10A8c3C8165079629794e7354dc9;
    uint256 constant public MAX_SUPPLY = 9999;
    bool public saleIsActive = false;
    bool public preSaleIsActive = true;
    uint256 public mintPrice = 69000000000000000; // 0.069 ETH
    uint256 public maxToMint = 10;
    uint256 public maxToMintWhitelist = 20;
    string _baseTokenURI;
    string _contractURI;
    address[] whitelistAddr;

    constructor(address _proxyRegistryAddress, address[] memory addrs) ERC721Tradable("Professor Elon Rocket Factory", "PERF", _proxyRegistryAddress) {
        whitelistAddr = addrs;
        for(uint i = 0; i < whitelistAddr.length; i++) {
            addAddressToWhitelist(whitelistAddr[i]);
        }
    }

    struct Whitelist {
        address addr;
        uint hasMinted;
    }
    mapping(address => Whitelist) public whitelist;

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
    }

    function setMaxToMintWhitelist(uint256 _maxToMint) external onlyOwner {
        maxToMintWhitelist = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        require(!isWhitelisted(addr), "Already whitelisted");
        whitelist[addr].addr = addr;
        whitelist[addr].hasMinted = 0;
        success = true;
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        whitelistAddr = addrs;
        for(uint i = 0; i < whitelistAddr.length; i++) {
            addAddressToWhitelist(whitelistAddr[i]);
        }
        success = true;
    }

    function isWhitelisted(address addr) public view returns (bool isWhiteListed) {
        return whitelist[addr].addr == addr;
    }

    function reserve(address to, uint256 numberOfTokens) public onlyOwner {
        uint i;
        for (i = 0; i < numberOfTokens; i++) {
            mintTo(to);
        }
    }

    function mint(address to, uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Sold out.");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "ETH sent is incorrect.");
        if(preSaleIsActive) {
            require(numberOfTokens <= maxToMintWhitelist, "Exceeds wallet pre-sale limit.");
            require(isWhitelisted(to), "Your address is not whitelisted.");
            require(whitelist[to].hasMinted.add(numberOfTokens) <= maxToMintWhitelist, "Exceeds per wallet pre-sale limit.");
            require(whitelist[to].hasMinted <= maxToMintWhitelist, "Exceeds per wallet pre-sale limit.");
            whitelist[to].hasMinted = whitelist[to].hasMinted.add(numberOfTokens);
        } else {
            require(numberOfTokens <= maxToMint, "Exceeds per transaction limit.");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            mintTo(to);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(5).div(100);
        uint256 wallet2Balance = balance.mul(73).div(10000);
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(msg.sender).transfer(balance.sub(wallet1Balance.add(wallet2Balance)));
    }
}