// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0

pragma solidity ^0.8.4;

/**
 * @dev ERC721 token receiver interface.
 */
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}