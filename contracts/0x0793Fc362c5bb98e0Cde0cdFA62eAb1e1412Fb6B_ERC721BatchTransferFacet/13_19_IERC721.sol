// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, basic interface (functions).
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev This interface only contains the standard functions. See IERC721Events for the events.
/// @dev Note: The ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 {
    /// @notice Sets or unsets an approval to transfer a single token on behalf of its owner.
    /// @dev Note: There can only be one approved address per token at a given time.
    /// @dev Note: A token approval gets reset when this token is transferred, including a self-transfer.
    /// @dev Reverts if `tokenId` does not exist.
    /// @dev Reverts if `to` is the token owner.
    /// @dev Reverts if the sender is not the token owner and has not been approved by the token owner.
    /// @dev Emits an {Approval} event.
    /// @param to The address to approve, or the zero address to remove any existing approval.
    /// @param tokenId The token identifier to give approval for.
    function approve(address to, uint256 tokenId) external;

    /// @notice Sets or unsets an approval to transfer all tokens on behalf of their owner.
    /// @dev Reverts if the sender is the same as `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator The address to approve for all tokens.
    /// @param approved True to set an approval for all tokens, false to unset it.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Unsafely transfers the ownership of a token to a recipient.
    /// @dev Note: Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer. Self-transfers are possible.
    /// @param tokenId The identifier of the token to transfer.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Gets the balance of an address.
    /// @dev Reverts if `owner` is the zero address.
    /// @param owner The address to query the balance of.
    /// @return balance The amount owned by the owner.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the owner of a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the owner of.
    /// @return tokenOwner The owner of the token identifier.
    function ownerOf(uint256 tokenId) external view returns (address tokenOwner);

    /// @notice Gets the approved address for a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the approval of.
    /// @return approved The approved address for the token identifier, or the zero address if no approval is set.
    function getApproved(uint256 tokenId) external view returns (address approved);

    /// @notice Gets whether an operator is approved for all tokens by an owner.
    /// @param owner The address which gives the approval for all tokens.
    /// @param operator The address which receives the approval for all tokens.
    /// @return approvedForAll Whether the operator is approved for all tokens by the owner.
    function isApprovedForAll(address owner, address operator) external view returns (bool approvedForAll);
}