// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Token specs and functions
 */
library TokenLib {
    // Spec types
    enum Spec {
        NONE,
        ERC721,
        ERC1155
    }

    function _getSpecString(Spec spec) internal pure returns (string memory) {
        if (spec == Spec.ERC721) {
           return "erc721";
        } else if (spec == Spec.ERC1155) {
            return "erc1155";
        } else {
            return "";
        }
    }

    function _erc721Transfer(address tokenAddress, uint256 tokenId, address from, address to) internal {
        // Transfer token
        IERC721(tokenAddress).transferFrom(from, to, tokenId);
    }

    function _erc1155Transfer(address tokenAddress, uint256 tokenId, uint256 value, address from, address to) internal {
        // Transfer token
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, value, "");
    }

}