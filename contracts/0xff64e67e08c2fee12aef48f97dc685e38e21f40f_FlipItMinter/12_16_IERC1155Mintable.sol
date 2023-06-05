// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IERC1155Mintable is IERC1155 {
    /// @notice Mints a `amount` of tokens and assigns them to `to`.
    /// @param to Address of the receiver.
    /// @param tokenId Id of the token.
    /// @param amount Amount of the tokens to mint.
    /// @param data Additional data.
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external;

    /// @notice Mints a `amount` of tokens and assigns them to `to`.
    /// @param to Address of the receiver.
    /// @param ids List of token ids to mint.
    /// @param amounts List of token amounts to mint.
    /// @param data Additional data.
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    /// @notice Destroys a `amount` of tokens of token type `id` from `from`.
    /// @param owner Address of the owner.
    /// @param tokenId Id of the token.
    /// @param amount Amount of the token to burn.
    function burn(address owner, uint256 tokenId, uint256 amount) external;

    /// @notice Destroys a `amount` of tokens of token type `id` from `from`.
    /// @param owner Address of the owner.
    /// @param ids List of token ids to burn.
    /// @param amounts List of token amounts to burn.
    function burnBatch(address owner, uint256[] memory ids, uint256[] memory amounts) external;
}