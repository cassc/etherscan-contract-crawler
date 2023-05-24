// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract MintingMachine is ERC721, Ownable {

    // ## Supply configuration
    uint64 public maxTokensPerMint = 1;  // default
    uint64 public totalSupply;  // optional, infinite if 0
    uint64 public totalMinted = 0;  // counter

    // ## Sale configuration
    bool public presaleActive;
    bool public saleActive;
    uint256 public salePrice;  // default price
    uint256 public presalePrice;  // default presale price
    
    // ## Presale configuration
    mapping(address => uint256) public presaleList;  // uint256 is number allowed for that address
    address[] private presaleAddresses;

    event MintToken(address recipient, uint256 num, uint256 lastTokenId);

    constructor(
        uint64 _totalSupply, 
        uint64 _maxTokensPerMint,
        uint256 _salePrice, 
        uint256 _presalePrice,
        bool _saleActive,
        bool _presaleActive,
        address[] memory _presaleAddresses, 
        uint256[] memory _presaleClaims
    ) {
        totalSupply = _totalSupply;
        maxTokensPerMint = _maxTokensPerMint;
        salePrice = _salePrice;
        presalePrice = _presalePrice;
        saleActive = _saleActive;
        presaleActive = _presaleActive;

        setPresaleList(_presaleAddresses, _presaleClaims);
    }

    // returns the address of the last token you minted
    function _mintToken(address addr, uint16 num, uint256 _price) internal returns (uint256) {
        // enforce supply limits
        require(num <= maxTokensPerMint, "Exceeded max tokens per mint");
        require(totalMinted + num <= totalSupply, "Mint would exceed the total supply");

        // ensure that the user has enough to pay for the tokens
        require(_price * num <= msg.value, "Insufficient funds. Unable to mint token");

        // run the mint
        for (uint16 i = 0; i < num; i++) {
            totalMinted++;
            _safeMint(addr, totalMinted);
        }

        emit MintToken(addr, num, totalMinted);

        return totalMinted;
    }

    // ## Sale Minting
    function saleMint(
        address addr, uint16 num
    ) public payable returns (uint256) {
        require(saleActive, "Sale must be active to mint tokens");
        return _mintToken(addr, num, salePrice);
    }

    // ## Presale Minting
    function presaleMint(
        address addr, uint16 num
    ) public payable returns (uint256) {
        require(presaleActive, "Presale must be active to mint tokens during the presale");
        require(presaleList[msg.sender] > 0, "Not eligible for presale mint");
        require(presaleList[msg.sender] >= num, "Not enough tokens avaliable");

        presaleList[msg.sender] -= num;
        return _mintToken(addr, num, presalePrice);
    }

    // ## Getters
    function getPresaleClaim(address addr) external view returns (uint256) {
        return presaleList[addr];
    }

    // ## Setters
    function setPresaleList(
        address[] memory addresses, uint256[] memory claims
    ) public onlyOwner {
        require(
            addresses.length == claims.length,
            "setPresaleList arguments do not have the same length"
        );

        for (uint256 i = 0; i < presaleAddresses.length; i++) {
            delete presaleList[presaleAddresses[i]];
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 claim = claims[i];
            require(claim <= maxTokensPerMint , "Presale claim exceeds maxTokensPerMint");
            presaleList[addresses[i]] = claim;
        }

        presaleAddresses = addresses;
    }

    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function setSaleActive(bool _saleActive) external onlyOwner {
        saleActive = _saleActive;
    }

    function setPresalePrice(uint256 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }

    function setPresaleActive(bool _presaleActive) external onlyOwner {
        presaleActive = _presaleActive;
    }
}