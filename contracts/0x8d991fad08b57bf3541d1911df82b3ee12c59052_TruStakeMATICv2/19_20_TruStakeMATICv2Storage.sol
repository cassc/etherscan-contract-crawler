// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

import "./Types.sol";

/// @title TruStakeMATICStorage
/// @author Pietro Demicheli (Field Labs)
abstract contract TruStakeMATICv2Storage {
    // Staker constants

    /// @notice address of MATIC on this chain (Ethereum and Goerli supported)
    address public stakingTokenAddress;

    /// @notice the stake manager contract deployed by Polygon
    address public stakeManagerContractAddress;

    /// @notice the validator share contract deployed by a validator
    address public validatorShareContractAddress;

    /// @notice the whitelist contract keeps track of what users can interact with
    ///   certain function in the TruStakeMATIC contract
    address public whitelistAddress;

    /// @notice the treasury gathers fees during the restaking of rewards as shares
    address public treasuryAddress;

    /// @notice size of fee taken on rewards
    /// @dev phi in basis points
    uint256 public phi;

    /// @notice size of fee taken on non-strict allocations
    /// @dev phi in basis points
    uint256 public distPhi;

    /// @notice cap on deposits into the vault
    uint256 public cap;

    /// @notice mapping to keep track of (user, amount) values for each unbond nonce
    /// @dev Maps nonce of validator unbonding to a Withdrawal (user & amount).
    mapping(uint256 => Withdrawal) public unbondingWithdrawals;

    /// @notice allocated balance mapping to ensure users can only withdraw fudns not still allocated to a user
    mapping(address => mapping(bool => Allocation)) public totalAllocated;

    /// @notice mapping of distributor to recipient to amount and shareprice
    mapping(address => mapping(address => mapping(bool => Allocation))) public allocations;

    /// @notice array of distributors to their recipients
    mapping(address => mapping(bool => address[])) public recipients;

    /// @notice array of recipients to their distributors
    mapping(address => mapping(bool => address[])) public distributors;

    /// @notice value to offset rounding errors (move up in next deployment)
    uint256 public epsilon;

    // @notice strictness lock (move up in next deployment)
    bool public allowStrict;

    /// @notice gap for upgradeability
    uint256[48] private __gap;
}