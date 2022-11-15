// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Mint {

    /// @notice event emitted when tokens are minted
    event Minted(
        address target,
        uint256 id,
        uint256 amount
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param amount the amount to mint
    function mint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external returns (uint256 tokenId);

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param amount the amount to mint
    function mintTo(
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external returns (uint256 tokenId);
}