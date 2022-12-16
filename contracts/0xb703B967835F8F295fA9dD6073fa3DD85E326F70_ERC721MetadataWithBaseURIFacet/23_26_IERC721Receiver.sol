// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, Tokens Receiver.
/// @notice Interface for supporting safe transfers from ERC721 contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handles the receipt of an ERC721 token.
    /// @dev Note: This function is called by an ERC721 contract after a safe transfer.
    /// @dev Note: The ERC721 contract address is always the message sender.
    /// @param operator The initiator of the safe transfer.
    /// @param from The previous token owner.
    /// @param tokenId The token identifier.
    /// @param data Optional additional data with no specified format.
    /// @return magicValue `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` (`0x150b7a02`) to accept, any other value to refuse.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4 magicValue);
}