// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title SignatureTransfer
 * @notice Handles ERC20 token transfers through signature based actions
 * @dev Requires user's token approval on the Permit2 contract
 */
interface IPermit2 {
    /**
     * @notice The token and amount details for a transfer signed in the permit transfer signature
     */
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /**
     * @notice The signed permit message for a single token transfer
     */
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /**
     * @notice Specifies the recipient address and amount for batched transfers.
     * @dev Recipients and amounts correspond to the index of the signed token permissions array.
     * @dev Reverts if the requested amount is greater than the permitted signed amount.
     */
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /**
     * @notice Used to reconstruct the signed permit message for multiple token transfers
     * @dev Do not need to pass in spender address as it is required that it is msg.sender
     * @dev Note that a user still signs over a spender address
     */
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /**
     * @notice Transfers a token using a signed permit message
     * @dev Reverts if the requested amount is greater than the permitted signed amount
     * @param permit The permit data signed over by the owner
     * @param owner The owner of the tokens to transfer
     * @param transferDetails The spender's requested transfer details for the permitted token
     * @param signature The signature to verify
     */
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /**
     * @notice Transfers multiple tokens using a signed permit message
     * @param permit The permit data signed over by the owner
     * @param owner The owner of the tokens to transfer
     * @param transferDetails Specifies the recipient and requested amount for the token transfer
     * @param signature The signature to verify
     */
    function permitTransferFrom(
        PermitBatchTransferFrom calldata permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}