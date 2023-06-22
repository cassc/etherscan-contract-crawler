// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/// @dev triggered when an address is the null address
error NullAddress();

error TokenDoesNotExist(uint256 tokenId);
error TokenAlreadyExists(uint256 tokenId);

error SafeTransferFailed(address from, address to, uint256 tokenId);

error TargetNonERC721Receiver(address target);

error TransferUnauthorized(
    address sender,
    address from,
    address to,
    uint256 tokenId,
    address tokenOwner
);

error IndexOutOfBounds(uint256 index, uint256 max);

error ApprovalForAllInvalid(address target, bool targetState);
error ApprovalInvalid(address account, uint256 tokenId);
error ApprovalUnauthorized(
    address from,
    address to,
    uint256 tokenId,
    address sender
);
error OperationFailed();

error InvalidAmount(uint256 amount, uint256 minAmount, uint256 maxAmount);
error AmountExceedsCap(uint256 amount, uint256 available, uint256 cap);
error InvalidMessageValue(uint256 value, uint256 needed);
error ZeroShares();