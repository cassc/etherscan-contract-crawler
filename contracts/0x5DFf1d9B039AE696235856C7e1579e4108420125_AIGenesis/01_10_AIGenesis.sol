// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AIGenesis is ERC721Optimized, Ownable {
    string[] public tokensURIs;
    event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721Optimized("AIGenesis", "AIGEN") {}

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "Token does not exist");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "You are not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function mint(address to, string memory tokenMetaURI) public onlyOwner {
        uint256 tokenId = totalSupply();
        _mint(to, tokenId);
        tokensURIs.push(tokenMetaURI);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokensURIs[tokenId];
	}
}