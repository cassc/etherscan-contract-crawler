// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import {
    IAccessControlEnumerable
} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { Multisig } from "../libraries/Multisig.sol";

/// @title Common interface for Wrap contracts on FLR and EVM chains.
interface IWrap is IAccessControlEnumerable {
    /// @dev Thrown when an operation is performed on a paused Wrap contract.
    error ContractPaused();

    /// @dev Thrown when the contract is not paused.
    error ContractNotPaused();

    /// @dev Thrown when the contract is already migrated.
    error ContractMigrated();

    /// @dev Thrown when the token is not allowlisted or the amount
    /// being deposited/approved is not in the range of min/maxAmount.
    error InvalidTokenAmount();

    /// @dev Thrown when the token config is invalid.
    error InvalidTokenConfig();

    /// @dev Thrown when the fee being set is higher than the maximum
    /// fee allowed.
    error FeeExceedsMaxFee();

    /// @dev Thrown when the recipient address is the zero address.
    error InvalidToAddress();

    /// @dev Thrown when the provided blocknumber is not of the most recent 256 blocks.
    error InvalidBlockHash();

    /// @dev Thrown when the daily volume exceeds the dailyLimit.
    error DailyLimitExhausted();

    /// @dev Thrown when the fee recipient address is the zero address.
    error InvalidFeeRecipient();

    /// @dev Emitted when a user deposits.
    /// @param id ID associated with the request.
    /// @param token Token deposited.
    /// @param amount Amount of tokens deposited, minus the fee.
    /// @param to Address to release the funds to.
    /// @param fee Fee subtracted from the original deposited amount.
    event Deposit(
        uint256 indexed id,
        address indexed token,
        uint256 amount,
        address to,
        uint256 fee
    );

    /// @dev Emitted when a new request is created.
    /// @param id ID associated with the request.
    /// @param mirrorToken Mirror token requested.
    /// @param amount Amount of tokens requested.
    /// @param to Address to release the funds to.
    event Requested(
        uint256 indexed id,
        address indexed mirrorToken,
        uint256 amount,
        address to
    );

    /// @dev Emitted when a request gets executed.
    /// @param id ID associated with the request.
    /// @param mirrorToken Mirror token requested.
    /// @param token Token approved.
    /// @param amount Amount approved, minus the fee.
    /// @param to Address to release the funds to.
    /// @param fee Fee charged on top of the approved amount.
    event Executed(
        uint256 indexed id,
        address indexed mirrorToken,
        address indexed token,
        uint256 amount,
        address to,
        uint256 fee
    );

    /// @dev Token information.
    /// @param maxAmount Maximum amount to deposit/approve.
    /// @param minAmount Minimum amount to deposit/approve.
    /// @notice Set max amount to zero to disable the token.
    /// @param dailyLimit Daily volume limit.
    struct TokenInfo {
        uint256 maxAmount;
        uint256 minAmount;
        uint256 dailyLimit;
    }

    /// @dev Token info that is stored in the contact storage.
    /// @param maxAmount Maximum amount to deposit/approve.
    /// @param minAmount Minimum amount to approve.
    /// @param minAmountWithFees Minimum amount to deposit, with fees included.
    /// @param dailyLimit Daily volume limit.
    /// @param consumedLimit Consumed daily volume limit.
    /// @param lastUpdated Last timestamp when the consumed limit was set to 0.
    /// @notice Set max amount to zero to disable the token.
    /// @notice Set daily limit to 0 to disable the daily limit. Consumed limit should
    /// always be less than equal to dailyLimit.
    /// @notice The minAmountWithFees is minAmount + depositFees(minAmount).
    /// On deposit, the amount should be greater than minAmountWithFees such that,
    /// after fee deduction, it is still greater equal than minAmount.
    struct TokenInfoStore {
        uint256 maxAmount;
        uint256 minAmount;
        uint256 minAmountWithFees;
        uint256 dailyLimit;
        uint256 consumedLimit;
        uint256 lastUpdated;
    }

    /// @dev Request information.
    /// @param id ID associated with the request.
    /// @param token Token requested.
    /// @param amount Amount of tokens requested.
    /// @param to Address to release the funds to.
    struct RequestInfo {
        uint256 id;
        address token;
        uint256 amount;
        address to;
    }

    /// @dev Returns whether or not the contract has been paused.
    /// @return paused True if the contract is paused, false otherwise.
    function paused() external view returns (bool paused);

    /// @dev Returns the number of deposits.
    function depositIndex() external view returns (uint256);

    /// @dev Returns the index of the request that will be executed next.
    function nextExecutionIndex() external view returns (uint256);

    /// @dev Returns info about a given validator.
    function validatorInfo(
        address validator
    ) external view returns (Multisig.SignerInfo memory);

    /// @dev Returns the number of attesters and their indeces for a given request hash.
    function attesters(
        bytes32 hash
    ) external view returns (uint16[] memory attesters, uint16 count);

    /// @dev Returns the validator fee basis points.
    function validatorFeeBPS() external view returns (uint16);

    /// @dev Update a token's configuration information.
    /// @param tokenInfo The token's new configuration info.
    /// @notice Set maxAmount to zero to disable the token.
    /// @notice Can only be called by the weak-admin.
    function configureToken(
        address token,
        TokenInfo calldata tokenInfo
    ) external;

    /// @dev Set the multisig configuration.
    /// @param config Multisig config.
    /// @notice Can only be called by the admin.
    function configureMultisig(Multisig.Config calldata config) external;

    /// @dev Configure validator fees.
    /// @param validatorFeeBPS Validator fee in basis points.
    /// @notice Can only be called by the weak-admin.
    function configureValidatorFees(uint16 validatorFeeBPS) external;

    /// @dev Deposit tokens to bridge to the other side.
    /// @param token Token being deposited.
    /// @param amount Amount of tokens being deposited.
    /// @param to Address to release the tokens to on the other side.
    /// @return The ID associated to the request.
    function deposit(
        address token,
        uint256 amount,
        address to
    ) external returns (uint256);

    /// @dev Approve and/or execute a given request.
    /// @param id ID associated with the request.
    /// @param token Token requested.
    /// @param amount Amount of tokens requested.
    /// @param to Address to release the funds to.
    /// @param recentBlockhash Block hash of `recentBlocknumber`
    /// @param recentBlocknumber Recent block number
    function approveExecute(
        uint256 id,
        address token,
        uint256 amount,
        address to,
        bytes32 recentBlockhash,
        uint256 recentBlocknumber
    ) external;

    /// @dev Approve and/or execute requests.
    /// @param requests Requests to approve and/or execute.
    function batchApproveExecute(
        RequestInfo[] calldata requests,
        bytes32 recentBlockhash,
        uint256 recentBlocknumber
    ) external;

    /// @dev Pauses the contract.
    /// @notice The contract can be paused by all addresses
    /// with pause role but can only be unpaused by the weak-admin.
    function pause() external;

    /// @dev Unpauses the contract.
    /// @notice The contract can be paused by all addresses
    /// with pause role but can only be unpaused by the weak-admin.
    function unpause() external;

    /// @dev Add a new validator to the contract.
    /// @param validator Address of the validator.
    /// @param isFirstCommittee True when adding the validator to the first committee.
    /// @param feeRecipient Address of the fee recipient.
    /// false when adding the validator to the second committee.
    /// @notice Can only be called by the admin.
    function addValidator(
        address validator,
        bool isFirstCommittee,
        address feeRecipient
    ) external;

    /// @dev Change fee recipient for a validator.
    /// @param validator Address of the validator.
    /// @param feeRecipient Address of the new fee recipient.
    function configureValidatorFeeRecipient(
        address validator,
        address feeRecipient
    ) external;

    /// @dev Remove existing validator from the contract.
    /// @param validator Address of the validator.
    /// @notice Can only be called by the weak-admin.
    /// @notice The fees accumulated by the validator are distributed before being removed.
    function removeValidator(address validator) external;

    /// @dev Allows to claim accumulated fees for a validator.
    /// @param validator Address of the validator.
    /// @notice Can be triggered by anyone but the fee is transfered to the
    /// set feeRecepient for the validator.
    function claimValidatorFees(address validator) external;

    /// @dev Forcefully set next next execution index.
    /// @param index The new next execution index.
    /// @notice Can only be called by the admin of the contract.
    function forceSetNextExecutionIndex(uint256 index) external;

    /// @dev Migrates the contract to a new address.
    /// @param _newContract Address of the new contract.
    /// @notice This function can only be called once in the lifetime of this
    /// contract by the admin.
    function migrate(address _newContract) external;
}