// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWHSForge {
    function _nftTokenForges(uint256 tokenId) external returns (address);
}

contract WHSPlaceholder is ERC721, Ownable {
    IWHSForge WHSForge;

    error NoTokenToUpdate();
    error TokenAlreadyUpdated();

    constructor(address whsForge)
        ERC721("WHSPlaceholder", "WHSP")
    {
        WHSForge = IWHSForge(whsForge);
    }

    /**
     * @dev allows anyone to mint/transfer a token to the address matching a forged WHS token
     * @dev burns the placeholder token if the WHS token is not forged
     * @param tokenId the forged token to mint/transfer to the original WHS token owner
     */
    function updateToken(uint256 tokenId) public {
        address forgedWHSOwner = WHSForge._nftTokenForges(tokenId);
        bool exists = _exists(tokenId);

        if (forgedWHSOwner == address(0)) {
            if (!exists) revert NoTokenToUpdate();
            _burn(tokenId);
        } else if (!exists) {
            _safeMint(forgedWHSOwner, tokenId);
        } else {
            address currentOwner = ownerOf(tokenId);
            if (currentOwner == forgedWHSOwner) {
                revert TokenAlreadyUpdated();
            }
            _safeTransfer(currentOwner, forgedWHSOwner, tokenId, "");
        }
    }

    function setWHSForge(address whsForge) external onlyOwner {
        WHSForge = IWHSForge(whsForge);
    }
}