// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../IMarketplaceTokenReceiver.sol";

/**
 * @dev Token specs and functions
 */
library TokenLib {
    // Spec types
    bytes32 internal constant _erc721bytes32 = keccak256(bytes('erc721'));
    bytes32 internal constant _erc1155bytes32 = keccak256(bytes('erc1155'));

    function _erc721Transfer(address tokenAddress, uint256 tokenId, address from, address to) internal {
        // Transfer token
        IERC721(tokenAddress).transferFrom(from, to, tokenId);
    }

    function _erc1155Transfer(address tokenReceiver, address tokenAddress, uint256 tokenId, uint256 value, address to) internal {
        // Call withdraw
        IMarketplaceTokenReceiver(tokenReceiver).transferERC1155(tokenAddress, tokenId, value, to);
    }

}