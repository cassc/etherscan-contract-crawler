// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the ETH transfer fails.
 */
error ETHTransferFail();

/**
 * @notice It is emitted if the ERC20 approval fails.
 */
error ERC20ApprovalFail();

/**
 * @notice It is emitted if the ERC20 transfer fails.
 */
error ERC20TransferFail();

/**
 * @notice It is emitted if the ERC20 transferFrom fails.
 */
error ERC20TransferFromFail();

/**
 * @notice It is emitted if the ERC721 transferFrom fails.
 */
error ERC721TransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeTransferFrom fails.
 */
error ERC1155SafeTransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeBatchTransferFrom fails.
 */
error ERC1155SafeBatchTransferFromFail();