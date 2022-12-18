// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of ERC721 in the Spanning Protocol
 *
 * NOTE: Spanning uses receiverAddress in favor of operatorAddress.
 * This pattern matches the language used to represent approvals elsewhere.
 */
interface ISpanningERC721 is IERC721 {
    /**
     * @dev Returns the number of tokens owned by an account.
     *
     * @param accountAddress - Address to be queried
     *
     * @return uint256 - Number of tokens owned by an account
     */
    function balanceOf(bytes32 accountAddress) external view returns (uint256);

    /**
     * @dev Returns the owner of the queried token.
     *
     * @param tokenId - Token to be queried
     *
     * @return bytes32 - Address of the owner of the queried token
     */
    function ownerOfSpanning(uint256 tokenId) external view returns (bytes32);

    /**
     * @dev Safely moves requested tokens between accounts, including data.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     * @param payload - Additional, unstructured data to be included
     */
    function safeTransferFrom(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId,
        bytes calldata payload
    ) external;

    /**
     * @dev Safely moves requested tokens between accounts.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     */
    function safeTransferFrom(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) external;

    /**
     * @dev Moves requested tokens between accounts.
     *
     * @param senderAddress - Address of the sender
     * @param receiverAddress - Address of the receiver
     * @param tokenId - Token to be transferred
     */
    function transferFrom(
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) external;

    /**
     * @dev Sets a token allowance for a pair of addresses (sender and receiver).
     *
     * @param receiverAddress - Address of the allowance receiver
     * @param tokenId - Token allowance to be approved
     */
    function approve(bytes32 receiverAddress, uint256 tokenId) external;

    /**
     * @dev Allows an account to have control over another account's tokens.
     *
     * @param receiverAddress - Address of the allowance receiver (gains control)
     * @param shouldApprove - Whether to approve or revoke the approval
     */
    function setApprovalForAll(bytes32 receiverAddress, bool shouldApprove)
        external;

    /**
     * @dev Returns the account approved for a token.
     *
     * @param tokenId - Token to be queried
     *
     * @return bytes32 - Address of the account approved for a token
     */
    function getApprovedSpanning(uint256 tokenId)
        external
        view
        returns (bytes32);

    /**
     * @dev Indicates if an account has total control over another's assets.
     *
     * @param senderAddress - Address of the allowance sender (cede control)
     * @param receiverAddress - Address of the allowance receiver (gains control)
     *
     * @return bool - Indicates whether the account is approved for all
     */
    function isApprovedForAll(bytes32 senderAddress, bytes32 receiverAddress)
        external
        view
        returns (bool);

    /**
     * @dev Emitted tokens are transferred
     *
     * Note that `amount` may be zero.
     *
     * @param senderAddress - Address initiating the transfer
     * @param receiverAddress - Address receiving the transfer
     * @param tokenId - Token under transfer
     */
    event SpanningTransfer(
        bytes32 indexed senderAddress,
        bytes32 indexed receiverAddress,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when an allowance pair changes.
     *
     * @param senderAddress - Address of the allowance sender
     * @param receiverAddress - Address of the allowance receiver
     * @param tokenId - Token under allowance
     */
    event SpanningApproval(
        bytes32 indexed senderAddress,
        bytes32 indexed receiverAddress,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when an account gives control to another account's tokens.
     *
     * @param senderAddress - Address of the allowance sender (cede control)
     * @param receiverAddress - Address of the allowance receiver (gains control)
     * @param approved - Whether the approval was approved or revoked
     */
    event SpanningApprovalForAll(
        bytes32 indexed senderAddress,
        bytes32 indexed receiverAddress,
        bool approved
    );
}