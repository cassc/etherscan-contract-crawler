// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice The records stored by the oracle contract informing the protocol about consensus layer activity. It is
/// computed and reported by off-chain oracle services.
/// @dev "current" quantities refer to the state at the `updateEndBlock` block number.
/// @dev "cumulative" quantities refer to sums up to the `updateEndBlock` block number.
/// @dev "window" quantities refer to sums over the block window between the `updateStartBlock` and `updateEndBlock`.
/// @param updateStartBlock The start of the oracle record block window. This should be 1 higher than the
/// updateEndBlock of the previous oracle record.
/// @param updateEndBlock The block number up to which this oracle record was computed (inclusive).
/// @param currentNumValidatorsNotWithdrawable The number of our validators that do not have the withdrawable status.
/// @param cumulativeNumValidatorsWithdrawable The total number of our validators that have the withdrawable status.
/// These validators have either the status `withdrawal_possible` or `withdrawal_done`. Note: validators can
/// fluctuate between the two statuses due to top ups.
/// @param windowWithdrawnPrincipalAmount The amount of principal that has been withdrawn from the consensus layer in
/// the analyzed block window.
/// @param windowWithdrawnRewardAmount The amount of rewards that has been withdrawn from the consensus layer in the
/// analysed block window.
/// @param currentTotalValidatorBalance The total amount of ETH in the consensus layer (i.e. the sum of all validator
/// balances). This is one of the major quantities to compute the total value controlled by the protocol.
/// @param cumulativeProcessedDepositAmount The total amount of ETH that has been deposited into and processed by the
/// consensus layer. This is used to prevent double counting of the ETH deposited to the consensus layer.
struct OracleRecord {
    uint64 updateStartBlock;
    uint64 updateEndBlock;
    uint64 currentNumValidatorsNotWithdrawable;
    uint64 cumulativeNumValidatorsWithdrawable;
    uint128 windowWithdrawnPrincipalAmount;
    uint128 windowWithdrawnRewardAmount;
    uint128 currentTotalValidatorBalance;
    uint128 cumulativeProcessedDepositAmount;
}

interface IOracleWrite {
    /// @notice Pushes a new record to the oracle.
    function receiveRecord(OracleRecord calldata record) external;
}

interface IOracleReadRecord {
    /// @notice Returns the latest validated record.
    /// @return `OracleRecord` The latest validated record.
    function latestRecord() external view returns (OracleRecord calldata);

    /// @notice Returns the record at the given index.
    /// @param idx The index of the record to retrieve.
    /// @return `OracleRecord` The record at the given index.
    function recordAt(uint256 idx) external view returns (OracleRecord calldata);

    /// @notice Returns the number of records in the oracle.
    /// @return `uint256` The number of records in the oracle.
    function numRecords() external view returns (uint256);
}

interface IOracleReadPending {
    /// @notice Returns the pending update.
    /// @return `OracleRecord` The pending update.
    function pendingUpdate() external view returns (OracleRecord calldata);

    /// @notice Indicates whether an oracle update is pending, i.e. if it was rejected by `_sanityCheckUpdate`.
    function hasPendingUpdate() external view returns (bool);
}

interface IOracleRead is IOracleReadRecord, IOracleReadPending {}

interface IOracleManager {
    /// @notice Sets the new oracle updater for the contract.
    /// @param newUpdater The new oracle updater.
    function setOracleUpdater(address newUpdater) external;
}

interface IOracle is IOracleWrite, IOracleRead, IOracleManager {}