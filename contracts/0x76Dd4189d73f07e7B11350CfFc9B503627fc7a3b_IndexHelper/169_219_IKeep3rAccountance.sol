// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rDisputable contract
/// @notice Disputes keepers, or if they're already disputed, it can resolve the case
/// @dev Argument `bonding` can be the address of either a token or a liquidity
interface IKeep3rAccountance {
    // Events

    /// @notice Emitted when the bonding process of a new keeper begins
    /// @param _keeper The caller of Keep3rKeeperFundable#bond function
    /// @param _bonding The asset the keeper has bonded
    /// @param _amount The amount the keeper has bonded
    event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

    /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
    /// @param _keeperOrJob The keeper or job that began the unbonding process
    /// @param _unbonding The liquidity pair or asset being unbonded
    /// @param _amount The amount being unbonded
    event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

    // Variables

    /// @notice Tracks the total KP3R earnings of a keeper since it started working
    /// @return _workCompleted Total KP3R earnings of a keeper since it started working
    function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

    /// @notice Tracks when a keeper was first registered
    /// @return timestamp The time at which the keeper was first registered
    function firstSeen(address _keeper) external view returns (uint256 timestamp);

    /// @notice Tracks if a keeper or job has a pending dispute
    /// @return _disputed Whether a keeper or job has a pending dispute
    function disputes(address _keeperOrJob) external view returns (bool _disputed);

    /// @notice Tracks how much a keeper has bonded of a certain token
    /// @return _bonds Amount of a certain token that a keeper has bonded
    function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

    /// @notice The current token credits available for a job
    /// @return _amount The amount of token credits available for a job
    function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

    /// @notice Tracks the amount of assets deposited in pending bonds
    /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
    function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

    /// @notice Tracks when a bonding for a keeper can be activated
    /// @return _timestamp Time at which the bonding for a keeper can be activated
    function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

    /// @notice Tracks when keeper bonds are ready to be withdrawn
    /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
    function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

    /// @notice Tracks how much keeper bonds are to be withdrawn
    /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
    function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

    /// @notice Checks whether the address has ever bonded an asset
    /// @return _hasBonded Whether the address has ever bonded an asset
    function hasBonded(address _keeper) external view returns (bool _hasBonded);

    // Methods
    /// @notice Lists all jobs
    /// @return _jobList Array with all the jobs in _jobs
    function jobs() external view returns (address[] memory _jobList);

    /// @notice Lists all keepers
    /// @return _keeperList Array with all the jobs in keepers
    function keepers() external view returns (address[] memory _keeperList);

    // Errors

    /// @notice Throws when an address is passed as a job, but that address is not a job
    error JobUnavailable();

    /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
    error JobDisputed();
}