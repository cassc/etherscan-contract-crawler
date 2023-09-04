// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

import {Withdrawal, Allocation} from "./Types.sol";

/// @title TruStakeMATICStorage
abstract contract TruStakeMATICv2Storage {
    // Staker constants

    /// @notice Address of MATIC on this chain (Ethereum and Goerli supported).
    address public stakingTokenAddress;

    /// @notice The stake manager contract deployed by Polygon.
    address public stakeManagerContractAddress;

    /// @notice The validator share contract deployed by a validator.
    address public validatorShareContractAddress;

    /// @notice The whitelist contract keeps track of what users can interact with
    ///   certain function in the TruStakeMATIC contract.
    address public whitelistAddress;

    /// @notice The treasury gathers fees during the restaking of rewards as shares.
    address public treasuryAddress;

    /// @notice Size of fee taken on rewards.
    /// @dev Fee in basis points.
    uint256 public phi;

    /// @notice Size of fee taken on non-strict allocations.
    /// @dev Distribution fee in basis points.
    uint256 public distPhi;

    /// @notice Cap on total amount staked with the validator.
    uint256 public cap;

    /// @notice Mapping to keep track of (user, amount) values for each unbond nonce.
    /// @dev Maps nonce of validator unbonding to a Withdrawal (user & amount).
    mapping(uint256 => Withdrawal) public unbondingWithdrawals;

    /// @notice Allocated balance mapping to ensure users can only withdraw funds not still allocated to a user.
    mapping(address => mapping(bool => Allocation)) public totalAllocated;

    /// @notice Mapping of distributor to recipient to amount and share price.
    mapping(address => mapping(address => mapping(bool => Allocation))) public allocations;

    /// @notice Array of distributors to their recipients.
    mapping(address => mapping(bool => address[])) public recipients;

    /// @notice Array of recipients to their distributors.
    mapping(address => mapping(bool => address[])) public distributors;

    /// @notice Value to offset rounding errors.
    uint256 public epsilon;

    /// @notice Strictness lock.
    bool public allowStrict;

    /// @notice Gap for upgradeability.
    uint256[48] private __gap;
}