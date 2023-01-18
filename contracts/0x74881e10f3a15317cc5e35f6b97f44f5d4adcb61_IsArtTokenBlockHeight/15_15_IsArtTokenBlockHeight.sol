// SPDX-License-Identifier: GPL-3.0-or-later
// Author:                  Rhea Myers <[email protected]>
// Copyright:               2023 Myers Studio, Ltd.
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// A contract where each token is/is not art based on the block height.
// Note that we cannot emit events for this, it has to be checked offchain.

contract IsArtTokenBlockHeight is ERC721, ERC721Enumerable, Pausable, Ownable {
    uint256 public constant NUM_TOKENS = 16;

    constructor() ERC721("Is Art (Token, Block Height)", "ISATBH") {
        for (uint256 i = 1; i <= NUM_TOKENS; i++) {
            _mint(msg.sender, i);
        }
    }

    function tokenIsArtAtBlockHeight (uint256 tokenId, uint256 blockHeight)
        public
        view
        returns (bytes6)
    {
        _requireMinted(tokenId);
        bytes6 status;
        if (((blockHeight / tokenId) % uint256(2)) == 1) {
            status = "is";
        } else {
            status = "is not";
        }
        return status;
    }

    function tokenIsArt (uint256 tokenId) external view returns (bytes6) {
        return tokenIsArtAtBlockHeight(
            tokenId,
            block.number // mythx-disable-line SWC-120
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}