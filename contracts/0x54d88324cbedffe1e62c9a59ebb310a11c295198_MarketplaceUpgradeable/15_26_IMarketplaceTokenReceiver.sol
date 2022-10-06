// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Token receiver for a given marketplace
 */
interface IMarketplaceTokenReceiver {
    /**
     * @dev decrement the balance of an ERC1155 token.  Only callable by the configured marketplace.
     */
    function decrementERC1155(address owner, address tokenAddress, uint256 tokenId, uint256 value) external;

    /**
     * @dev transfer the balance of an ERC1155 token.  Only callable by the configured marketplace.
     */
    function transferERC1155(address tokenAddress, uint256 tokenId, uint256 value, address to) external;

    /**
     * @dev withdraw deposited ERC1155 token.  Only callable by the depositor of a token and limited to the balance deposited.
     */
    function withdrawERC1155(address tokenAddress, uint256 tokenId, uint256 value) external;

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes calldata) external returns(bytes4);
}