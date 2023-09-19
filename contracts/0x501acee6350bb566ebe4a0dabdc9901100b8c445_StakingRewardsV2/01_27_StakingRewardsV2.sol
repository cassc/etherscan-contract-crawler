// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./../utils/Governable.sol";
import "./../interfaces/utils/IRegistry.sol";
import "./../interfaces/payment/ICoverPaymentManager.sol";
import "./../interfaces/staking/IxsLocker.sol";
import "./../interfaces/staking/IStakingRewardsV2.sol";


/**
 * @title Staking Rewards(V2)
 * @author solace.fi
 * @notice Rewards users for staking in [`xsLocker`](./xsLocker).
 *
 * Deposits and withdrawls are made to [`xsLocker`](./xsLocker) and rewards come from `StakingRewardsV2`. All three are paid in [**SOLACE**](./../SOLACE). `StakingRewardsV2` will be registered as an [`xsListener`](./../interfaces/staking/IxsListener). Any time a lock is updated [`registerLockEvent()`](#registerlockevent) will be called and the staking information of that lock will be updated.
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**SOLACE**](./../SOLACE) to all lock holders split relative to the value of their locks. The base value of a lock is its `amount` of [**SOLACE**](./../SOLACE). Its multiplier is 2.5x when `end` is 4 years from now, 1x when unlocked, and linearly decreasing between the two. The value of a lock is its base value times its multiplier.
 *
 * Note that transferring [**SOLACE**](./../SOLACE) to this contract will not give you any rewards. You should deposit your [**SOLACE**](./../SOLACE) into [`xsLocker`](./xsLocker) via `createLock()`.
 *
 * @dev Lock information is stored in [`xsLocker`](./xsLocker) and mirrored here for bookkeeping and efficiency. Should that information differ, [`xsLocker`](./xsLocker) is the ground truth and this contract will attempt to sync with it.
 */
contract StakingRewardsV2 is IStakingRewardsV2, ReentrancyGuard, Governable {
    using EnumerableSet for EnumerableSet.UintSet;

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice The maximum duration of a lock in seconds.
    uint256 public constant override MAX_LOCK_DURATION = 4 * 365 days; // 4 years
    /// @notice The vote power multiplier at max lock in bps.
    uint256 public constant override MAX_LOCK_MULTIPLIER_BPS = 25000;  // 2.5X
    /// @notice The vote power multiplier when unlocked in bps.
    uint256 public constant override UNLOCKED_MULTIPLIER_BPS = 10000; // 1X
    // 1 bps = 1/10000
    uint256 internal constant MAX_BPS = 10000;
    // multiplier to increase precision
    uint256 internal constant Q12 = 1e12;

    /// @notice The registry address.
    address public registry;
    /// @notice The cover payment manager address.
    address public coverPaymentManager;
    /// @notice [**SOLACE**](./../SOLACE) token.
    address public override solace;
    /// @notice The [**xsLocker**](../xsLocker) contract.
    address public override xsLocker;
    /// @notice Amount of SOLACE distributed per second.
    uint256 public override rewardPerSecond;
    /// @notice When the farm will start.
    uint256 public override startTime;
    /// @notice When the farm will end.
    uint256 public override endTime;
    /// @notice Last time rewards were distributed or farm was updated.
    uint256 public override lastRewardTime;
    /// @notice Accumulated rewards per share, times 1e12.
    uint256 public override accRewardPerShare;
    /// @notice Value of tokens staked by all farmers.
    uint256 public override valueStaked;

    /// @notice Information about each lock.
    /// @dev lock id => lock info
    mapping(uint256 => StakedLockInfo) private _lockInfo;

    /// @notice True if info about a lock was migrated from a previous version of StakingRewardsV1.
    mapping(uint256 => bool) public override wasLockMigrated;

    /**
     * @notice Constructs the StakingRewardsV2 contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ The [`Registry`](./Registry) contract address.
     */
    constructor(address governance_, address registry_) Governable(governance_) {
        // set registry
        _setRegistry(registry_);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Information about each lock.
    /// @dev lock id => lock info
    function stakedLockInfo(uint256 xsLockID) external view override returns (StakedLockInfo memory) {
        return _lockInfo[xsLockID];
    }

    /**
     * @notice Calculates the accumulated balance of [**SOLACE**](./../SOLACE) for specified lock.
     * @param xsLockID The ID of the lock to query rewards for.
     * @return reward Total amount of withdrawable reward tokens.
     */
    function pendingRewardsOfLock(uint256 xsLockID) external view override returns (uint256 reward) {
        // get lock information
        StakedLockInfo storage lockInfo = _lockInfo[xsLockID];
        // math
        uint256 accRewardPerShare_ = accRewardPerShare;
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > lastRewardTime && valueStaked != 0) {
            // solhint-disable-next-line not-rely-on-time
            uint256 tokenReward = getRewardAmountDistributed(lastRewardTime, block.timestamp);
            accRewardPerShare_ += tokenReward * Q12 / valueStaked;
        }
        return lockInfo.value * accRewardPerShare_ / Q12 - lockInfo.rewardDebt + lockInfo.unpaidRewards;
    }

    /**
     * @notice Calculates the reward amount distributed between two timestamps.
     * @param from The start of the period to measure rewards for.
     * @param to The end of the period to measure rewards for.
     * @return amount The reward amount distributed in the given period.
     */
    function getRewardAmountDistributed(uint256 from, uint256 to) public view override returns (uint256 amount) {
        // validate window
        from = Math.max(from, startTime);
        to = Math.min(to, endTime);
        // no reward for negative window
        if (from > to) return 0;
        return (to - from) * rewardPerSecond;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Called when an action is performed on a lock.
     * @dev Called on transfer, mint, burn, and update.
     * Either the owner will change or the lock will change, not both.
     * @param xsLockID The ID of the lock that was altered.
     * @param oldOwner The old owner of the lock.
     * @param newOwner The new owner of the lock.
     * @param oldLock The old lock data.
     * @param newLock The new lock data.
     */
    // solhint-disable-next-line no-unused-vars
    function registerLockEvent(uint256 xsLockID, address oldOwner, address newOwner, Lock calldata oldLock, Lock calldata newLock) external override nonReentrant {
        update();
        _harvest(xsLockID);
    }

    /**
     * @notice Updates staking information.
     */
    function update() public override {
        // emit event regardless if any changes were made
        emit Updated();
        // dont update needlessly
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= lastRewardTime) return;
        if (valueStaked == 0) {
            // solhint-disable-next-line not-rely-on-time
            lastRewardTime = Math.min(block.timestamp, endTime);
            return;
        }
        // update math
        // solhint-disable-next-line not-rely-on-time
        uint256 tokenReward = getRewardAmountDistributed(lastRewardTime, block.timestamp);
        accRewardPerShare += tokenReward * Q12 / valueStaked;
        // solhint-disable-next-line not-rely-on-time
        lastRewardTime = Math.min(block.timestamp, endTime);
    }

    /**
     * @notice Updates and sends a lock's rewards.
     * @param xsLockID The ID of the lock to process rewards for.
     */
    function harvestLock(uint256 xsLockID) external override nonReentrant {
        update();
        _harvest(xsLockID);
    }

    /**
     * @notice Updates and sends multiple lock's rewards.
     * @param xsLockIDs The IDs of the locks to process rewards for.
     */
    function harvestLocks(uint256[] memory xsLockIDs) external override nonReentrant {
        update();
        uint256 len = xsLockIDs.length;
        for(uint256 i = 0; i < len; i++) {
            _harvest(xsLockIDs[i]);
        }
    }

    /**
     * @notice Withdraws a lock's rewards and deposits it back into the lock.
     * Can only be called by the owner of the lock.
     * @param xsLockID The ID of the lock to compound.
     */
    function compoundLock(uint256 xsLockID) external override {
        IxsLocker locker = IxsLocker(xsLocker);
        require(msg.sender == locker.ownerOf(xsLockID), "not owner");
        update();
        (uint256 transferAmount, ) = _updateLock(xsLockID);
        if(transferAmount != 0) locker.increaseAmount(xsLockID, transferAmount);
    }

    /**
     * @notice Withdraws multiple lock's rewards and deposits it into lock.
     * Can only be called by the owner of the locks.
     * @param xsLockIDs The ID of the locks to compound.
     * @param increasedLockID The ID of the lock to deposit into.
     */
    function compoundLocks(uint256[] calldata xsLockIDs, uint256 increasedLockID) external override {
        update();
        IxsLocker locker = IxsLocker(xsLocker);
        uint256 len = xsLockIDs.length;
        uint256 transferAmount = 0;
        for(uint256 i = 0; i < len; i++) {
            uint256 xsLockID = xsLockIDs[i];
            require(msg.sender == locker.ownerOf(xsLockID), "not owner");
            (uint256 ta, ) = _updateLock(xsLockID);
            transferAmount += ta;
        }
        if(transferAmount != 0) locker.increaseAmount(increasedLockID, transferAmount);
    }

    /**
     * @notice Updates and sends a lock's rewards.
     * @param xsLockID The ID of the lock to process rewards for.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
     */
    function harvestLockForScp(uint256 xsLockID, uint256 price, uint256 priceDeadline, bytes calldata signature) external override nonReentrant {
        update();
        _harvestForScp(xsLockID, price, priceDeadline, signature);
    }

    /**
     * @notice Updates and sends multiple lock's rewards.
     * @param xsLockIDs The IDs of the locks to process rewards for.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
     */
    function harvestLocksForScp(uint256[] memory xsLockIDs, uint256 price, uint256 priceDeadline, bytes calldata signature) external override nonReentrant {
        update();
        uint256 len = xsLockIDs.length;
        for(uint256 i = 0; i < len; i++) {
            _harvestForScp(xsLockIDs[i], price, priceDeadline, signature);
        }
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Updates and sends a lock's rewards.
     * @param xsLockID The ID of the lock to process rewards for.
     */
    function _harvest(uint256 xsLockID) internal {
        (uint256 transferAmount, address receiver) = _updateLock(xsLockID);
        if(receiver != address(0x0) && transferAmount != 0) SafeERC20.safeTransfer(IERC20(solace), receiver, transferAmount);
    }

    /**
     * @notice Updates and buys `SCP` with a lock's rewards.
     * @param xsLockID The ID of the lock to process rewards for.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
     */
    function _harvestForScp(uint256 xsLockID, uint256 price, uint256 priceDeadline, bytes calldata signature) internal {
        (uint256 transferAmount, address owner) = _updateLock(xsLockID);
        require(msg.sender == owner, "not owner");
        // buy scp
        if (owner != address(0x0) && transferAmount != 0) {
            ICoverPaymentManager(coverPaymentManager).depositNonStable(solace, owner, transferAmount, price, priceDeadline, signature);
        }
    }

    /**
     * @notice Updates and returns a lock's rewards.
     * @param xsLockID The ID of the lock to process rewards for.
     * @return transferAmount The amount of [**SOLACE**](./../SOLACE) to transfer to the receiver.
     * @return receiver The user to receive the [**SOLACE**](./../SOLACE).
     */
    function _updateLock(uint256 xsLockID) internal returns (uint256 transferAmount, address receiver) {
        // math
        uint256 accRewardPerShare_ = accRewardPerShare;
        // get lock information
        StakedLockInfo memory lockInfo = _lockInfo[xsLockID];
        (bool exists, address owner, Lock memory lock) = _fetchLockInfo(xsLockID);
        // accumulate and transfer unpaid rewards
        lockInfo.unpaidRewards += lockInfo.value * accRewardPerShare_ / Q12 - lockInfo.rewardDebt;
        if(lockInfo.owner != address(0x0)){
            uint256 balance = IERC20(solace).balanceOf(address(this));
            transferAmount = Math.min(lockInfo.unpaidRewards, balance);
            lockInfo.unpaidRewards -= transferAmount;
        }
        // update lock value
        uint256 oldValue = lockInfo.value;
        uint256 newValue = _calculateLockValue(lock.amount, lock.end);
        lockInfo.value = newValue;
        lockInfo.rewardDebt = newValue * accRewardPerShare_ / Q12;
        if(oldValue != newValue) valueStaked = valueStaked - oldValue + newValue;
        // update lock owner. maintain pre-burn owner in case of unpaid rewards
        if(owner != lockInfo.owner && exists) {
            lockInfo.owner = owner;
        }
        _lockInfo[xsLockID] = lockInfo;
        emit LockUpdated(xsLockID);
        receiver = (lockInfo.owner == address(0x0)) ? owner : lockInfo.owner;
        return (transferAmount, receiver);
    }

    /**
     * @notice Fetches up to date information about a lock.
     * @param xsLockID The ID of the lock to query.
     * @return exists True if the lock exists.
     * @return owner The owner of the lock or the zero address if it doesn't exist.
     * @return lock The lock itself.
     */
    function _fetchLockInfo(uint256 xsLockID) internal view returns (bool exists, address owner, Lock memory lock) {
        IxsLocker locker = IxsLocker(xsLocker);
        exists = locker.exists(xsLockID);
        if(exists) {
            owner = locker.ownerOf(xsLockID);
            lock = locker.locks(xsLockID);
        } else {
            owner = address(0x0);
            lock = Lock(0, 0);
        }
        return (exists, owner, lock);
    }

    /**
     * @notice Calculates the value of a lock.
     * The base value of a lock is its `amount` of [**SOLACE**](./../SOLACE). Its multiplier is 2.5x when `end` is 4 years from now, 1x when unlocked, and linearly decreasing between the two. The value of a lock is its base value times its multiplier.
     * @param amount The amount of [**SOLACE**](./../SOLACE) in the lock.
     * @param end The unlock timestamp of the lock.
     * @return value The boosted value of the lock.
     */
    function _calculateLockValue(uint256 amount, uint256 end) internal view returns (uint256 value) {
        uint256 base = amount * UNLOCKED_MULTIPLIER_BPS / MAX_BPS;
        // solhint-disable-next-line not-rely-on-time
        uint256 bonus = (end <= block.timestamp)
            ? 0 // unlocked
            // solhint-disable-next-line not-rely-on-time
            : amount * (end - block.timestamp) * (MAX_LOCK_MULTIPLIER_BPS - UNLOCKED_MULTIPLIER_BPS) / (MAX_LOCK_DURATION * MAX_BPS); // locked
        return base + bonus;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of [**SOLACE**](./../SOLACE) to distribute per second.
     * Only affects future rewards.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param rewardPerSecond_ Amount to distribute per second.
     */
    function setRewards(uint256 rewardPerSecond_) external override onlyGovernance {
        update();
        rewardPerSecond = rewardPerSecond_;
        emit RewardsSet(rewardPerSecond_);
    }

    /**
     * @notice Sets the farm's start and end time. Used to extend the duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param startTime_ The new start time.
     * @param endTime_ The new end time.
     */
    function setTimes(uint256 startTime_, uint256 endTime_) external override onlyGovernance {
        require(startTime_ <= endTime_, "invalid window");
        startTime = startTime_;
        endTime = endTime_;
        emit FarmTimesSet(startTime_, endTime_);
        update();
    }

    /**
     * @notice Rescues tokens that may have been accidentally transferred in.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param token The token to rescue.
     * @param amount Amount of the token to rescue.
     * @param receiver Account that will receive the tokens.
     */
    function rescueTokens(address token, uint256 amount, address receiver) external override onlyGovernance {
        SafeERC20.safeTransfer(IERC20(token), receiver, amount);
    }

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _registry The address of `Registry` contract.
     */
    function setRegistry(address _registry) external override onlyGovernance {
        _setRegistry(_registry);
    }

    /**
     * @notice Sets registry and related contract addresses.
     * @param _registry The registry address to set.
     */
    function _setRegistry(address _registry) internal {
        require(_registry != address(0x0), "zero address registry");
        registry = _registry;
        IRegistry reg = IRegistry(_registry);

        // set scp
        (, address coverPaymentManagerAddr) = reg.tryGet("coverPaymentManager");
        require(coverPaymentManagerAddr != address(0x0), "zero address payment manager");
        coverPaymentManager = coverPaymentManagerAddr;

        // set solace
        (, address solaceAddr) = reg.tryGet("solace");
        require(solaceAddr != address(0x0), "zero address solace");
        solace = solaceAddr;

        // set xslocker
        (, address xslockerAddr) = reg.tryGet("xsLocker");
        require(xslockerAddr != address(0x0), "zero address xslocker");
        xsLocker = xslockerAddr;

        // approve solace
        IERC20(solaceAddr).approve(xslockerAddr, type(uint256).max);
        IERC20(solaceAddr).approve(coverPaymentManagerAddr, type(uint256).max);

        emit RegistrySet(_registry);
    }

    /**
     * @notice Migrates information about locks from a previous version of staking rewards.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param stakingRewardsV1 The previous version of staking rewards.
     * @param xsLockIDs The IDs of the locks to migrate.
     */
    function migrate(address stakingRewardsV1, uint256[] memory xsLockIDs) external override onlyGovernance {
        update();
        // loop over locks
        for(uint256 i = 0; i < xsLockIDs.length; i++) {// migrate
            _migrateLock(stakingRewardsV1, xsLockIDs[i]);
        }
    }

    /**
     * @notice Migrates information about a lock from a previous version of staking rewards.
     * @param stakingRewardsV1 The previous version of staking rewards.
     * @param xsLockID The IDs of the locks to migrate.
     */
    function _migrateLock(address stakingRewardsV1, uint256 xsLockID) internal {
        // can only migrate each lock once
        if(wasLockMigrated[xsLockID]) return;
        // math
        uint256 accRewardPerShare_ = accRewardPerShare;
        // get lock information
        StakedLockInfo memory lockInfo = _lockInfo[xsLockID];
        (bool exists, address owner, Lock memory lock) = _fetchLockInfo(xsLockID);
        // accumulate unpaid rewards
        lockInfo.unpaidRewards += (
            // from this StakingRewardsV2
            (lockInfo.value * accRewardPerShare_ / Q12 - lockInfo.rewardDebt) +
            // from previous StakingRewardsV1
            (IStakingRewardsV2(stakingRewardsV1).pendingRewardsOfLock(xsLockID)) );
        // update lock value
        uint256 oldValue = lockInfo.value;
        uint256 newValue = _calculateLockValue(lock.amount, lock.end);
        lockInfo.value = newValue;
        lockInfo.rewardDebt = newValue * accRewardPerShare_ / Q12;
        if(oldValue != newValue) valueStaked = valueStaked - oldValue + newValue;
        // update lock owner. maintain pre-burn owner in case of unpaid rewards
        if(owner != lockInfo.owner && exists) {
            lockInfo.owner = owner;
        }
        _lockInfo[xsLockID] = lockInfo;
        wasLockMigrated[xsLockID] = true;
        emit LockUpdated(xsLockID);
    }
}