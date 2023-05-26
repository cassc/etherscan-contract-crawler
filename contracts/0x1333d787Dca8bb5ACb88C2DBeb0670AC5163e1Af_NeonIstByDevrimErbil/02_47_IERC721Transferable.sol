// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IERC721Transferable
 * @author @NiftyMike | @NFTCulture
 * @dev Super thin interface for invoking ERC721 transfers.
 */
interface IERC721Transferable {
    function balanceOf(address owner) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
}