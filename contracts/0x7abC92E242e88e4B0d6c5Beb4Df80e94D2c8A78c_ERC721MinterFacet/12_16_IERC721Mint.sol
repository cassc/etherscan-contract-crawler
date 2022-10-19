// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC721Mint {

    /// @notice mint tokens of specified amount to the specified address
    function mint(
        uint256 quantity,
        bytes calldata data
    ) external returns (uint256 tokenId);

    /// @notice mint tokens of specified amount to the specified address
    function mintTo(
        address receiver,
        uint256 quantity,
        bytes calldata data
    ) external returns (uint256 tokenId);

}