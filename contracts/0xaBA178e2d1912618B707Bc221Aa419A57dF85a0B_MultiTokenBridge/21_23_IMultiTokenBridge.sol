// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title MultiTokenBridge types interface
 * @author CloudWalk Inc.
 * @dev See terms in the comments of the {IMultiTokenBridge} interface.
 */
interface IMultiTokenBridgeTypes {
    /// @dev Enumeration of bridge operation modes.
    enum OperationMode {
        Unsupported,   // 0 Relocation/accommodation is unsupported (the default value).
        BurnOrMint,    // 1 Relocation/accommodation is supported by burning/minting tokens.
        LockOrTransfer // 2 Relocation/accommodation is supported by locking/transferring tokens.
    }

    /// @dev Enumeration of relocation statuses.
    enum RelocationStatus {
        Nonexistent, // 0 The relocation does not exist.
        Pending,     // 1 The status right after relocation is requested.
        Canceled,    // 2 The relocation has been canceled before processing.
        Processed,   // 3 The relocation has been successfully processed by the bridge.
        Revoked,     // 4 The relocation has been revoked during the processing. Tokens has been returned to the user.
        Aborted      // 5 The relocation has been aborted. Tokens cannot be returned to the user for some reason.
    }

    /// @dev Structure with data of a single relocation operation.
    struct Relocation {
        address token;           // The address of the token used for relocation.
        address account;         // The account that requested the relocation.
        uint256 amount;          // The amount of tokens to relocate.
        RelocationStatus status; // The current status of the relocation.
    }
}

/**
 * @title MultiTokenBridge interface
 * @author CloudWalk Inc.
 * @dev The bridge contract interface  that supports  bridging of multiple tokens.
 *
 * Terms used in the context of bridge contract operations:
 *
 * - relocation -- the relocation of tokens from one chain (a source chain) to another one (a destination chain).
 * - to relocate -- to move tokens from the current chain to another one.
 * - accommodation -- placing tokens from another chain in the current chain.
 * - to accommodate -- to meet a relocation coming from another chain and place tokens in the current chain.
 */
interface IMultiTokenBridge is IMultiTokenBridgeTypes {
    /// @dev Emitted when a new relocation is requested.
    event RequestRelocation(
        uint256 indexed chainId, // The destination chain ID of the relocation.
        address indexed token,   // The address of the token used for relocation.
        address indexed account, // The account that requested the relocation.
        uint256 amount,          // The amount of tokens to relocate.
        uint256 nonce            // The relocation nonce.
    );

    /// @dev Emitted when the relocation status is changed.
    event ChangeRelocationStatus(
        uint256 indexed chainId,        // The destination chain ID of the relocation.
        address indexed token,          // The address of the token used for relocation.
        address indexed account,        // The account that requested the relocation.
        uint256 amount,                 // The amount of tokens to relocate.
        uint256 nonce,                  // The relocation nonce.
        RelocationStatus currentStatus, // The current status of the relocation.
        RelocationStatus previousStatus // The previous status of the relocation.
    );

    /// @dev Emitted when a previously requested relocation is processed.
    event Relocate(
        uint256 indexed chainId, // The destination chain ID of the relocation.
        address indexed token,   // The address of the token used for relocation.
        address indexed account, // The account that requested the relocation.
        uint256 amount,          // The amount of tokens to relocate.
        uint256 nonce,           // The nonce of the relocation.
        OperationMode mode       // The mode of relocation.
    );

    /// @dev Emitted when a new accommodation takes place.
    event Accommodate(
        uint256 indexed chainId, // The source chain ID of the accommodation.
        address indexed token,   // The address of the token used for accommodation.
        address indexed account, // The account that requested the correspondent relocation in the source chain.
        uint256 amount,          // The amount of tokens to relocate.
        uint256 nonce,           // The nonce of the accommodation.
        OperationMode mode       // The mode of accommodation.
    );

    /**
     * @dev Returns the counter of pending relocations for a given destination chain.
     * @param chainId The ID of the destination chain.
     */
    function getPendingRelocationCounter(uint256 chainId) external view returns (uint256);

    /**
     * @dev Returns the last processed relocation nonce for a given destination chain.
     * @param chainId The ID of the destination chain.
     */
    function getLastProcessedRelocationNonce(uint256 chainId) external view returns (uint256);

    /**
     * @dev Returns a relocation mode for a given destination chain and token.
     * @param chainId The ID of the destination chain.
     * @param token The address of the token.
     */
    function getRelocationMode(uint256 chainId, address token) external view returns (OperationMode);

    /**
     * @dev Returns relocation details for a given destination chain and nonce.
     * @param chainId The ID of the destination chain.
     * @param nonce The nonce of the relocation to return.
     */
    function getRelocation(uint256 chainId, uint256 nonce) external view returns (Relocation memory);

    /**
     * @dev Returns an accommodation mode for a given source chain and token.
     * @param chainId The ID of the source chain.
     * @param token The address of the token.
     */
    function getAccommodationMode(uint256 chainId, address token) external view returns (OperationMode);

    /**
     * @dev Returns the last accommodation nonce for a given source chain.
     * @param chainId The ID of the source chain.
     */
    function getLastAccommodationNonce(uint256 chainId) external view returns (uint256);

    /**
     * @dev Returns relocation details for a given destination chain and a range of nonces.
     * @param chainId The ID of the destination chain.
     * @param nonce The nonce of the first relocation to return.
     * @param count The number of relocations in the range to return.
     * @return relocations The array of relocations for the requested range.
     */
    function getRelocations(
        uint256 chainId,
        uint256 nonce,
        uint256 count
    ) external view returns (Relocation[] memory relocations);

    /**
     * @dev Requests a new relocation with transferring tokens from an account to the bridge.
     *
     * The new relocation will be pending until it is processed.
     * This function is expected to be called by any account.
     *
     * Emits a {RequestRelocation} event.
     *
     * @param chainId The ID of the destination chain.
     * @param token The address of the token used for relocation.
     * @param amount The amount of tokens to relocate.
     * @return nonce The nonce of the new relocation.
     */
    function requestRelocation(
        uint256 chainId,
        address token,
        uint256 amount
    ) external returns (uint256 nonce);

    /**
     * @dev Cancels multiple pending relocations with transferring tokens back from the bridge to initiator accounts.
     *
     * This function can be called by a limited number of accounts that are allowed to execute bridging operations.
     *
     * Emits a {ChangeRelocationStatus} event for each relocation.
     *
     * @param chainId The destination chain ID of the relocations to cancel.
     * @param nonces The array of pending relocation nonces to cancel.
     */
    function cancelRelocations(uint256 chainId, uint256[] memory nonces) external;

    /**
     * @dev Processes specified count of pending relocations.
     *
     * If relocations are executed in `BurnOrMint` mode tokens will be burnt.
     * If relocations are executed in `LockOrTransfer` mode tokens will be locked on the bridge.
     * The canceled relocations are skipped during the processing.
     * This function can be called by a limited number of accounts that are allowed to execute bridging operations.
     *
     * Emits a {Relocate} event for each non-canceled relocation.
     *
     * @param chainId The destination chain ID of the pending relocations.
     * @param count The number of pending relocations to process.
     */
    function relocate(uint256 chainId, uint256 count) external;

    /**
     * @dev Revokes a processed relocation with returning tokens back to the initiator account.
     *
     * If relocations are executed in `BurnOrMint` mode tokens will be minted to the account.
     * If relocations are executed in `LockOrTransfer` mode tokens will be transferred from the bridge to the account.
     * This function can be called by a limited number of accounts that are allowed to execute bridging operations.
     *
     * Emits a {ChangeRelocationStatus} event.
     *
     * @param chainId The destination chain ID of the relocation to revoke.
     * @param nonce The nonce of the relocation to revoke.
     */
    function revokeRelocation(uint256 chainId, uint256 nonce) external;

    /**
     * @dev Aborts a pending or processed relocation without returning the tokens to the initiator account.
     *
     * This function can be called by a limited number of accounts that are allowed to execute bridging operations.
     * This function is expected to be called when there is no possibility to return tokens to the account,
     * e.g. if the account was blacklisted during the bridge operations.
     *
     * Emits a {ChangeRelocationStatus} event.
     *
     * @param chainId The destination chain ID of the relocation to abort.
     * @param nonce The nonce of the relocation to abort.
     */
    function abortRelocation(uint256 chainId, uint256 nonce) external;

    /**
     * @dev Accommodates tokens from a source chain.
     *
     * If accommodations are executed in `BurnOrMint` mode tokens will be minted.
     * If accommodations are executed in `LockOrTransfer` mode tokens will be transferred from the bridge account.
     * Tokens will be minted or transferred only for non-canceled relocations.
     * This function can be called by a limited number of accounts that are allowed to execute bridging operations.
     *
     * Emits a {Accommodate} event for each non-canceled relocation.
     *
     * @param chainId The ID of the source chain.
     * @param nonce The nonce of the first relocation to accommodate.
     * @param relocations The array of relocations to accommodate.
     */
    function accommodate(
        uint256 chainId,
        uint256 nonce,
        Relocation[] memory relocations
    ) external;

    /**
     * @dev Returns the address of the bridge guard.
     */
    function bridgeGuard() external view returns(address);
}