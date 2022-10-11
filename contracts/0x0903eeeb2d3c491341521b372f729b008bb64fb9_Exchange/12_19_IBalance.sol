// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBalance {
    /// @dev Returns the amount of tokens owned by `account`. ERC20 tokens.
    function balanceOf(address account) external view returns (uint256);
    /// @dev Returns the owner of the `tokenId` token. ERC721 tokens.
    function ownerOf(uint256 tokenId) external view returns (address owner);
    /// @dev Returns the amount of tokens of token type `id` owned by `account`. ERC1155 tokens.
    function balanceOf(address account, uint256 id) external view returns (uint256);
}