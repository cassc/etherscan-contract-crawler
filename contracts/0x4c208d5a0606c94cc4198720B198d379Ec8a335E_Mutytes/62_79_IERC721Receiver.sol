// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of a token
     * @param operator The operator's address
     * @param from The previous owner's address
     * @param tokenId The token id
     * @param data Additional data
     * @return selector The function selector
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}