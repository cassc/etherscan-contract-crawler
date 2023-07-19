// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract Parent {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract TheVoguMUTTS is ERC721Enumerable, Ownable {  
  
    Parent private parent; 
    string public PROVENANCE;
    bool public claimIsActive = false;
    string private baseURI;

    constructor(address parentAddress) ERC721("The Vogu: MUTTS", "MUTTS") {
        parent = Parent(parentAddress);
    }

    function setProvenanceHash(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
  
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setClaimState(bool newState) public onlyOwner {
        claimIsActive = newState;
    }
  
    function claim(uint256 startingIndex, uint256 numberOfTokens) public {
        require(claimIsActive, "Claim period is not active.");
        require(numberOfTokens > 0, "Must claim at least one token.");
        uint balance = parent.balanceOf(msg.sender);
        require(balance >= numberOfTokens, "Insufficient parent tokens.");
        require(balance >= startingIndex + numberOfTokens, "Insufficient parent tokens.");

        for (uint i = 0; i < balance && i < numberOfTokens; i++) {
            uint tokenId = parent.tokenOfOwnerByIndex(msg.sender, i + startingIndex);
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function claimAll() public {
        claim(0, parent.balanceOf(msg.sender));
    }

    function claimByTokenIds(uint256[] calldata tokenIds) public {
        require(claimIsActive, "Claim period is not active.");
        require(tokenIds.length > 0, "Must claim at least one token.");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(parent.ownerOf(tokenIds[i]) == msg.sender, "Must own all parent tokens.");
            if (!_exists(tokenIds[i])) {
                _safeMint(msg.sender, tokenIds[i]);
            }
        }
    }
}