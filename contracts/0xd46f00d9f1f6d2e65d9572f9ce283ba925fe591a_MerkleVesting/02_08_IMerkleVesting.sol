// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title Allows anyone to claim a token if they exist in a merkle root, but only over time.
interface IMerkleVesting {
    /// @notice The struct holding a specific cohort's data and the individual claim statuses.
    /// @param data The struct holding a specific cohort's data.
    /// @param claims Stores the amount of claimed funds per address.
    /// @param disabledState A packed array of booleans. If true, the individual user cannot claim anymore.
    struct Cohort {
        CohortData data;
        mapping(address => uint256) claims;
        mapping(uint256 => uint256) disabledState;
    }

    /// @notice The struct holding a specific cohort's data.
    /// @param merkleRoot The merkle root of the merkle tree containing account balances available to claim.
    /// @param distributionEnd The unix timestamp that marks the end of the token distribution.
    /// @param vestingEnd The unix timestamp that marks the end of the vesting period.
    /// @param vestingPeriod The length of the vesting period in seconds.
    /// @param cliffPeriod The length of the cliff period in seconds.
    struct CohortData {
        bytes32 merkleRoot;
        uint64 distributionEnd;
        uint64 vestingEnd;
        uint64 vestingPeriod;
        uint64 cliffPeriod;
    }

    /// @notice Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    /// @notice Returns the id/Merkle root of the cohort ending at the latest.
    function lastEndingCohort() external view returns (bytes32);

    /// @notice Returns the parameters of a specific cohort.
    /// @param cohortId The Merkle root of the cohort.
    function getCohort(bytes32 cohortId) external view returns (CohortData memory);

    /// @notice Returns the amount of funds an account can claim at the moment.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    /// @param account The address of the account to query.
    /// @param fullAmount The full amount of funds the account can claim.
    function getClaimableAmount(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 fullAmount
    ) external view returns (uint256);

    /// @notice Returns the amount of funds an account has claimed.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address of the account to query.
    function getClaimed(bytes32 cohortId, address account) external view returns (uint256);

    /// @notice Check if the address in a cohort at the index is excluded from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    function isDisabled(bytes32 cohortId, uint256 index) external view returns (bool);

    /// @notice Exclude the address in a cohort at the index from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    function setDisabled(bytes32 cohortId, uint256 index) external;

    /// @notice Allows the owner to add a new cohort.
    /// @param merkleRoot The Merkle root of the cohort. It will also serve as the cohort's ID.
    /// @param distributionDuration The length of the token distribtion period in seconds.
    /// @param vestingPeriod The length of the vesting period of the tokens in seconds.
    /// @param cliffPeriod The length of the cliff period in seconds.
    function addCohort(
        bytes32 merkleRoot,
        uint256 distributionDuration,
        uint64 vestingPeriod,
        uint64 cliffPeriod
    ) external;

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list (so the full amount).
    /// @param merkleProof A an array of values from the generated input list.
    function claim(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Allows the owner to reclaim the tokens after the distribution has ended.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a call to #addCohort succeeds.
    /// @param cohortId The Merkle root of the cohort.
    event CohortAdded(bytes32 cohortId);

    /// @notice This event is triggered whenever a call to #claim succeeds.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address that claimed the tokens.
    /// @param amount The amount of tokens the address received.
    event Claimed(bytes32 cohortId, address account, uint256 amount);

    /// @notice This event is triggered whenever a call to #withdraw succeeds.
    /// @param account The address that received the tokens.
    /// @param amount The amount of tokens the address received.
    event Withdrawn(address account, uint256 amount);

    /// @notice Error thrown when there's nothing to withdraw.
    error AlreadyWithdrawn();

    /// @notice Error thrown when a cohort with the provided id does not exist.
    error CohortDoesNotExist();

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the cliff period is not over yet.
    /// @param cliff The time when the cliff period ends.
    /// @param timestamp The current timestamp.
    error CliffNotReached(uint256 cliff, uint256 timestamp);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    error DistributionOngoing(uint256 current, uint256 end);

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();

    /// @notice Error thrown when a transfer failed.
    /// @param token The address of token attempted to be transferred.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address token, address from, address to);

    /// @notice Error thrown when a function receives invalid parameters.
    error InvalidParameters();

    /// @notice Error thrown when a cohort with an already existing merkle tree is attempted to be added.
    error MerkleRootCollision();

    /// @notice Error thrown when the input address has been excluded from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address that does not satisfy the requirements.
    error NotInVesting(bytes32 cohortId, address account);
}