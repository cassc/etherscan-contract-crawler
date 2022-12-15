// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Access.sol";

contract BounceERC721V2 is ERC721, Access {
    constructor (string memory name_, string memory symbol_, Mode mode_) public ERC721(name_, symbol_) Access(mode_) {}

    // tokenid => creator address
    mapping(uint256 => address) public creator;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        super._setBaseURI(baseURI_);
    }

    function mint(address to, uint256 tokenId) external checkRole {
        super._safeMint(to, tokenId);
        creator[tokenId] = to;
    }

    function burn(uint256 tokenId) external checkRole {
        super._burn(tokenId);
        creator[tokenId] = address(0);
    }

    function batchMint(address to, uint256 fromTokenId, uint256 toTokenId) external checkRole {
        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            super._safeMint(to, tokenId);
            creator[tokenId] = to;
        }
    }
}