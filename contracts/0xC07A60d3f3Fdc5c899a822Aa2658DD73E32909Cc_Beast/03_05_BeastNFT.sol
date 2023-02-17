// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// MrXoople : Digital Artist & Industrial Designer
// Xoople MEANS Forest
// Artist Official Web => MrXoople.com
// Project Guide Line => MrXoople.com/beast

contract Beast is ERC721A, Ownable {
    uint256 public COLLECTION_SIZE;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;

    mapping(address => uint256) public walletMints;

constructor() payable ERC721A('BEAST', 'BEAST') {
    COLLECTION_SIZE = 1810;
    }

function setIsPublicMintEnable(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenUri, _toString(tokenId), ".json"));
    }

function __publicMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "completed");
        _safeMint(owner(), quantity);
    }


function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }

}