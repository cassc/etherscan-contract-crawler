// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "borrow/interfaces/ICoreBorrow.sol";
import { IVaultManagerListing } from "borrow/interfaces/IVaultManager.sol";

/// @title BaseStorage
/// @author Angle Labs, Inc.
/// @dev Variables, references, parameters and events needed in the `BorrowStaker` contract
contract BorrowStakerStorage is Initializable {
    /// @notice Base used for parameter computation
    /// @dev Large base because when `(amount * BASE_36) / totalSupply()` if `amount << totalSupply`
    /// rounding can be terrible. Setting the base higher increases the maximum decimals a reward can have.
    uint256 public constant BASE_36 = 10**36;

    // ================================= REFERENCES ================================

    /// @notice Core borrow contract handling access control
    ICoreBorrow public coreBorrow;

    // ================================= VARIABLES =================================

    /// @notice Token decimal
    uint8 internal _decimals;
    /// @notice Last time rewards were claimed by this contract
    uint32 internal _lastRewardsClaimed;
    /// @notice List of all the vaultManager which have the staker as collateral
    IVaultManagerListing[] internal _vaultManagers;
    /// @notice Maps an address to whether it is a compatible `VaultManager` that has this contract
    /// as a collateral
    mapping(address => uint256) public isCompatibleVaultManager;
    /// @notice Maps an address to the collateral it owns across all whitelisted VaultManager
    mapping(address => uint256) public delegatedBalanceOf;
    /// @notice Maps each reward token to a track record of cumulated rewards
    mapping(IERC20 => uint256) public integral;
    /// @notice Maps pairs of `(token,user)` to the currently pending claimable rewards
    mapping(IERC20 => mapping(address => uint256)) public pendingRewardsOf;
    /// @notice Maps pairs of `(token,user)` to a track record of cumulated personal rewards
    mapping(IERC20 => mapping(address => uint256)) public integralOf;

    uint256[41] private __gap;

    // =================================== EVENTS ==================================

    event AddVaultManager(address indexed vaultManager);
    event CoreBorrowUpdated(address indexed oldCoreBorrow, address indexed newCoreBorrow);
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);
    event Recovered(address indexed token, address indexed to, uint256 amount);

    // =================================== ERRORS ==================================

    error InvalidToken();
    error NotGovernor();
    error NotGovernorOrGuardian();
    error NotVaultManager();
    error TransferAmountExceedsAllowance();
    error ZeroAddress();
    error InvalidVaultManager();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
}