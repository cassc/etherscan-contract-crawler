// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract travelspread is ERC721A, Ownable {

    uint256 MAX_SUPPLY = 10000;
    bool locked = false;

    string public baseURI = "ipfs://bafybeieyetlp2c2vubffzjjap7utuz5jwo2k5b5kupvezfchc5tnfg4fh4/";

    constructor() ERC721A("travelspread", "trs") {}

    function mint(uint256 quantity) public onlyOwner{
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity > 0, "Not enough quantity to mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    function setLocked(bool _locked) public onlyOwner{
        locked = _locked;
    }

    function batchNFTsTransfer(
        address[] memory addresses,
        uint256[] memory tokens
    ) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            super.transferFrom(msg.sender, addresses[i], tokens[i]);
        }
    } 

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _beforeTokenTransfers(
        address ,
        address ,
        uint256 ,
        uint256 
    ) internal view override {
        require(!locked, "Cannot transfer - currently locked");
    }

    
}