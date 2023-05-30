//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import { SafeERC20, IERC20 } from "../ecosystem/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAdapter.sol";
import "./interfaces/IMigrationController.sol";
import "./interfaces/ILiquidityMigrationV2.sol";
import "../helpers/Timelocked.sol";

contract LiquidityMigrationV2 is ILiquidityMigrationV2, Timelocked {
    using SafeERC20 for IERC20;

    address public controller;
    address public genericRouter;
    address public migrationCoordinator;
    address public emergencyReceiver;

    bool public paused;
    mapping (address => bool) public adapters; // adapter -> bool
    mapping (address => uint256) public totalStaked; // lp -> total staked
    mapping (address => address) public strategies; // lp -> enso strategy
    mapping (address => mapping (address => uint256)) public staked; // user -> lp -> stake

    event Staked(address adapter, address strategy, uint256 amount, address account);
    event Migrated(address adapter, address lp, address strategy, address account);
    event Created(address adapter, address lp, address strategy, address account);
    event Refunded(address lp, uint256 amount, address account);
    event EmergencyMigration(address lp, uint256 amount, address receiver);

    /**
    * @dev Require adapter registered
    */
    modifier onlyRegistered(address adapter) {
        require(adapters[adapter], "Not registered");
        _;
    }

    /**
    * @dev Require adapter allows lp
    */
    modifier onlyWhitelisted(address adapter, address lp) {
        require(IAdapter(adapter).isWhitelisted(lp), "Not whitelist");
        _;
    }

    modifier onlyLocked() {
        require(block.timestamp < unlocked, "Unlocked");
        _;
    }

    modifier isPaused() {
        require(paused, "Not paused");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor(
        address[] memory adapters_,
        uint256 unlock_,
        uint256 modify_
    )
        Timelocked(unlock_, modify_, msg.sender)
    {
        for (uint256 i = 0; i < adapters_.length; i++) {
            adapters[adapters_[i]] = true;
        }
    }

    function setStrategy(address lp, address strategy) external onlyOwner notPaused {
        require(
            IMigrationController(controller).initialized(strategy),
            "Not enso strategy"
        );
        if (strategies[lp] != address(0)) {
          // This value can be changed as long as no migration is in progress
          require(IERC20(strategies[lp]).balanceOf(address(this)) == 0, "Already set");
        }
        strategies[lp] = strategy;
    }

    function setStake(
        address user,
        address lp,
        address adapter,
        uint256 amount
    )
        external
        override
        notPaused
        onlyLocked
    {
        require(msg.sender == migrationCoordinator, "Wrong sender");
        _stake(user, lp, adapter, amount);
    }

    function stake(
        address lp,
        uint256 amount,
        address adapter
    )
        external
        notPaused
        onlyLocked
        onlyRegistered(adapter)
    {
        _transferFromAndStake(lp, adapter, amount);
    }

    function batchStake(
        address[] memory lps,
        uint256[] memory amounts,
        address adapter
    )
        external
        notPaused
        onlyLocked
        onlyRegistered(adapter)
    {
        require(lps.length == amounts.length, "Incorrect arrays");
        for (uint256 i = 0; i < lps.length; i++) {
            _transferFromAndStake(lps[i], adapter, amounts[i]);
        }
    }

    function buyAndStake(
        address lp,
        address adapter,
        address exchange,
        uint256 minAmountOut,
        uint256 deadline
    )
        external
        payable
        notPaused
        onlyLocked
        onlyRegistered(adapter)
        onlyWhitelisted(adapter, lp)
    {
        require(msg.value > 0, "No value");
        _buyAndStake(lp, msg.value, adapter, exchange, minAmountOut, deadline);
    }

    function migrateAll(
        address lp,
        address adapter
    )
        external
        override
        notPaused
        onlyOwner
        onlyUnlocked
        onlyRegistered(adapter)
        onlyWhitelisted(adapter, lp)
    {
        address strategy = strategies[lp];
        require(strategy != address(0), "Strategy not initialized");
        uint256 totalStake = totalStaked[lp];
        delete totalStaked[lp];
        uint256 strategyBalanceBefore = IStrategy(strategy).balanceOf(address(this));
        IERC20(lp).safeTransfer(genericRouter, totalStake);
        IMigrationController(controller).migrate(IStrategy(strategy), IStrategyRouter(genericRouter), IERC20(lp), IAdapter(adapter), totalStake);
        uint256 strategyBalanceAfter = IStrategy(strategy).balanceOf(address(this));
        assert((strategyBalanceAfter - strategyBalanceBefore) == totalStake);
    }

    function refund(address user, address lp) external onlyOwner {
        _refund(user, lp);
    }

    function withdraw(address lp) external {
        _refund(msg.sender, lp);
    }

    function claim(address lp) external {
        require(totalStaked[lp] == 0, "Not yet migrated");
        uint256 amount = staked[msg.sender][lp];
        require(amount > 0, "No claim");
        delete staked[msg.sender][lp];

        address strategy = strategies[lp];
        IERC20(strategy).safeTransfer(msg.sender, amount);
        emit Migrated(address(0), lp, strategy, msg.sender);
    }

    function emergencyMigrate(IERC20 lp) external isPaused onlyOwner {
        require(emergencyReceiver != address(0), "Emergency receiver not set");
        uint256 balance = lp.balanceOf(address(this));
        require(balance > 0, "No balance");
        lp.safeTransfer(emergencyReceiver, balance);
        emit EmergencyMigration(address(lp), balance, emergencyReceiver);
    }

    function pause() external notPaused onlyOwner {
        paused = true;
    }

    function unpause() external isPaused onlyOwner {
        paused = false;
    }

    function _stake(
        address user,
        address lp,
        address adapter,
        uint256 amount
    )
        internal
    {
        staked[user][lp] += amount;
        totalStaked[lp] += amount;
        emit Staked(adapter, lp, amount, user);
    }

    function _transferFromAndStake(
        address lp,
        address adapter,
        uint256 amount
    )
        internal
        onlyWhitelisted(adapter, lp)
    {
        require(amount > 0, "No amount");
        IERC20(lp).safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, lp, adapter, amount);
    }

    function _buyAndStake(
        address lp,
        uint256 amount,
        address adapter,
        address exchange,
        uint256 minAmountOut,
        uint256 deadline
    )
        internal
    {
        uint256 balanceBefore = IERC20(lp).balanceOf(address(this));
        IAdapter(adapter).buy{value: amount}(lp, exchange, minAmountOut, deadline);
        uint256 amountAdded = IERC20(lp).balanceOf(address(this)) - balanceBefore;
        _stake(msg.sender, lp, adapter, amountAdded);
    }

    function _refund(address user, address lp) internal {
        require(totalStaked[lp] > 0, "Not refundable");
        uint256 amount = staked[user][lp];
        require(amount > 0, "No stake");
        delete staked[user][lp];
        totalStaked[lp] -= amount;

        IERC20(lp).safeTransfer(user, amount);
        emit Refunded(lp, amount, user);
    }

    function updateController(address newController)
        external
        onlyOwner
    {
        require(controller != newController, "Controller already exists");
        controller = newController;
    }

    function updateGenericRouter(address newGenericRouter)
        external
        onlyOwner
    {
        require(genericRouter != newGenericRouter, "GenericRouter already exists");
        genericRouter = newGenericRouter;
    }

    function updateCoordinator(address newCoordinator)
        external
        onlyOwner
    {
        require(migrationCoordinator != newCoordinator, "Coordinator already exists");
        migrationCoordinator = newCoordinator;
    }

    function updateEmergencyReceiver(address newReceiver)
        external
        onlyOwner
    {
        require(emergencyReceiver != newReceiver, "Receiver already exists");
        emergencyReceiver = newReceiver;
    }

    function addAdapter(address adapter)
        external
        onlyOwner
    {
        require(!adapters[adapter], "Adapter already exists");
        adapters[adapter] = true;
    }

    function removeAdapter(address adapter)
        external
        onlyOwner
    {
        require(adapters[adapter], "Adapter does not exist");
        adapters[adapter] = false;
    }

    function hasStaked(address account, address lp)
        external
        view
        returns(bool)
    {
        return staked[account][lp] > 0;
    }
}