/// ===============================
/// ===== Audit: NOT IN SCOPE =====
/// ===============================

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {IERC20MintableBurnable} from "@interfaces/IERC20MintableBurnable.sol";
import {ITokenLocker} from "@interfaces/ITokenLocker.sol";
import {IPRV} from "@interfaces/IPRV.sol";
import {IPRVRouter} from "@interfaces/IPRVRouter.sol";

import {SafeCast} from "@oz/utils/math/SafeCast.sol";

interface ISharesTimelocker {
    function getLocksOfLength(address account) external view returns (uint256);

    function locksOf(address account, uint256 id) external view returns (uint256, uint32, uint32);

    function migrate(address staker, uint256 lockId) external;

    function canEject(address account, uint256 lockId) external view returns (bool);

    function migrateMany(address staker, uint256[] calldata lockIds) external returns (uint256);
}

/// @dev This contract assumes all locks are properly ejected
contract Upgradoor {
    using SafeCast for uint256;
    using SafeCast for uint32;

    address public immutable AUXO;
    address public immutable PRV;
    address public immutable DOUGH;
    address public immutable veDOUGH;
    address public immutable prvRouter;
    ITokenLocker public tokenLocker;

    // Old lock AVG_SECONDS_MONTH constant (private in that contract)
    uint32 public constant AVG_SECONDS_MONTH = 2628000;
    ISharesTimelocker public oldLock;

    event AggregatedAndBoosted(address owner, uint256 amountMigrated);
    event AggregatedToARV(address owner, uint256 amountMigrated);
    event AggregateToPRV(address owner, uint256 amountMigrated);
    event AggregateToPRVAndStake(address owner, uint256 amountMigratedAndStaker);
    event LockUpgradedARV(address receiver, uint256 idx, uint256 amountMigrated);
    event LockUpgradedPRV(address receiver, uint256 idx, uint256 amountMigrated);
    event LockUpgradedPRVAndStake(address receiver, uint256 idx, uint256 amountMigratedAndStaker);

    constructor(
        address _oldLock, // old timelock
        address _auxo,
        address _dough,
        address _tokenLocker,
        address _prv,
        address _veDOUGH,
        address _router
    ) {
        oldLock = ISharesTimelocker(_oldLock);
        AUXO = _auxo;
        DOUGH = _dough;
        veDOUGH = _veDOUGH;
        PRV = _prv;
        tokenLocker = ITokenLocker(_tokenLocker);
        prvRouter = _router;

        IERC20(AUXO).approve(_tokenLocker, type(uint256).max);
        IERC20(AUXO).approve(_prv, type(uint256).max);
        IERC20(AUXO).approve(_router, type(uint256).max);
    }

    // -----------------
    // --- Modifiers ---
    // -----------------

    /// @notice restricts depositing into smart contracts unless whitelisted
    /// @dev fetches whitelisting data from the *destination* locker
    ///      This is not a perfect approach, code size in constructors is zero and addresses can be precomputed.
    ///      However, it prevents accidental transfers by honest users.
    modifier onlyEOAorWL(address _receiver) {
        require(_receiver.code.length == 0 || tokenLocker.whitelisted(_receiver), "Not EOA or WL");
        _;
    }

    // -----------------
    // ---- Preview ----
    // -----------------

    /// @notice Returns the expected PRV return amount when upgrading all veDOUGH locks to PRV.
    function previewAggregateToPRV(address receiver) external view returns (uint256) {
        (, uint256 amount,) = getAmountAndLongestDuration(receiver);
        return getRate(amount);
    }

    /// @notice Returns the expected AUXO return amount when aggregating all veDOUGH locks and boosting to 36 months
    /// @dev boosting to max will yield a 1:1 conversion from veDOUGH -> AUXO
    function previewAggregateAndBoost(address receiver) external view returns (uint256) {
        (, uint256 amount,) = getAmountAndLongestDuration(receiver);
        return getRate(amount);
    }

    /// @notice Aggregate all locks to ARV based on the remaining months of the longest lock
    function previewAggregateARV(address receiver) external view returns (uint256) {
        (, uint256 totalAmount,) = getAmountAndLongestDuration(receiver);
        (, uint32 longestLockedAt, uint32 longestDuration,) = getNextLongestLock(receiver);
        uint256 month = getMonthsNewLock(longestLockedAt, longestDuration);
        return tokenLocker.previewDepositByMonths(getRate(totalAmount).toUint192(), month, receiver);
    }

    function previewUpgradeSingleLockARV(address lockOwner, address receiver) external view returns (uint256) {
        if (lockOwner != receiver) {
            require(IERC20(veDOUGH).balanceOf(address(receiver)) == 0, "Invalid receiver");
        }
        (uint256 amount, uint32 longestLockedAt, uint32 duration,) = getNextLongestLock(lockOwner);

        uint256 month = getMonthsNewLock(longestLockedAt, duration);
        // If returned value is zero the lock is over
        require(month > 0, "Lock expired");
        return tokenLocker.previewDepositByMonths(getRate(amount).toUint192(), month, receiver);
    }

    /// @notice Returns the expected PRV return amount when upgrading a single lock.
    function previewUpgradeSingleLockPRV(address lockOwner) external view returns (uint256) {
        (uint256 amount,,,) = getNextLongestLock(lockOwner);
        return getRate(amount);
    }

    // -------------------------
    // ---- Write functions ----
    // -------------------------

    /// @notice aggregates all the locks to one at max time
    function aggregateAndBoost() external {
        uint256 amountMigrated = _runMigrationAll();
        tokenLocker.depositByMonths(amountMigrated.toUint192(), 36, msg.sender);
        emit AggregatedAndBoosted(msg.sender, amountMigrated);
    }

    /// @notice aggregates all the locks to one ARV
    /// @dev Aggregated to *REMAINING* months on the longest lock
    /// @dev If the remaining months are < 6 than we default to 6
    function aggregateToARV() external {
        (, uint32 longestLockedAt, uint32 duration,) = getNextLongestLock(msg.sender);
        uint256 month = getMonthsNewLock(longestLockedAt, duration);
        uint256 amountMigrated = _runMigrationAll();
        tokenLocker.depositByMonths(amountMigrated.toUint192(), month, msg.sender);
        emit AggregatedToARV(msg.sender, amountMigrated);
    }

    /// @notice aggregates all the locks to PRV
    function aggregateToPRV() external {
        // Migrate function will also mint AUXO to this contract
        uint256 amountMigrated = _runMigrationAll();
        IPRV(PRV).depositFor(msg.sender, amountMigrated);
        emit AggregateToPRV(msg.sender, amountMigrated);
    }

    /// @notice aggregates all the locks to PRV
    function aggregateToPRVAndStake() external {
        // Migrate function will also mint AUXO to this contract
        uint256 amountMigrated = _runMigrationAll();
        IPRVRouter(prvRouter).convertAndStake(amountMigrated, msg.sender);
        emit AggregateToPRVAndStake(msg.sender, amountMigrated);
    }

    /// @notice If the remaning months are < 6 than we default to 6
    function upgradeSingleLockARV(address receiver) external onlyEOAorWL(receiver) {
        if (msg.sender != receiver) {
            require(IERC20(veDOUGH).balanceOf(address(receiver)) == 0, "Invalid receiver");
        }

        (, uint32 longestLockedAt, uint32 duration, uint256 idx) = getNextLongestLock(msg.sender);
        uint256 month = getMonthsNewLock(longestLockedAt, duration);

        // If returned value is zero the lock is over
        require(month > 0, "Lock expired");
        uint256 amountMigrated = _runMigrationOne(idx);
        tokenLocker.depositByMonths(amountMigrated.toUint192(), month, receiver);
        emit LockUpgradedARV(receiver, idx, amountMigrated);
    }

    /// @notice If receiver has an existing lock it will revert
    /// because otherwise receiver would not be able to migrate his own lock
    function upgradeSingleLockPRV(address receiver) external {
        (,,, uint256 idx) = getNextLongestLock(msg.sender);
        uint256 amountMigrated = _runMigrationOne(idx);
        IPRV(PRV).depositFor(receiver, amountMigrated);
        emit LockUpgradedPRV(receiver, idx, amountMigrated);
    }

    function upgradeSingleLockPRVAndStake(address receiver) external {
        (,,, uint256 idx) = getNextLongestLock(msg.sender);
        uint256 amountMigrated = _runMigrationOne(idx);
        IPRVRouter(prvRouter).convertAndStake(amountMigrated, receiver);
        emit LockUpgradedPRVAndStake(receiver, idx, amountMigrated);
    }

    // ----------------
    // --- Internal ---
    // ----------------

    function _runMigrationAll() internal returns (uint256) {
        uint256 numLocks = oldLock.getLocksOfLength(msg.sender);
        require(numLocks > 0, "Nothing to migrate");

        uint256 j;
        uint256[] memory ids = new uint256[](numLocks);

        for (uint256 i = 0; i < numLocks;) {
            (uint256 amount, uint32 lockedAt, uint32 duration) = oldLock.locksOf(msg.sender, i);

            // We don't call migrate on expired/empty because it would revert
            // It might happen that migrate gets never called because all locks are expired
            if (uint256(lockedAt + duration) <= block.timestamp || amount == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            ids[j] = i;

            unchecked {
                ++i;
                ++j;
            }
        }

        uint256 balanceMigrated = oldLock.migrateMany(msg.sender, ids);
        uint256 delta = getRate(balanceMigrated);
        require(delta > 0, "Nothing to mint");

        IERC20MintableBurnable(AUXO).mint(address(this), delta);
        return delta;
    }

    function _runMigrationOne(uint256 idx) internal returns (uint256) {
        uint256 balanceDoughBefore = IERC20(DOUGH).balanceOf(address(this));

        oldLock.migrate(msg.sender, idx);

        uint256 balanceDoughAfter = IERC20(DOUGH).balanceOf(address(this));
        uint256 delta = getRate(balanceDoughAfter - balanceDoughBefore);
        require(delta > 0, "Nothing to mint");

        IERC20MintableBurnable(AUXO).mint(address(this), delta);
        return delta;
    }

    // ------------
    // --- View ---
    // ------------

    /// @notice Returns the number of months remaining for the lock, with a minimum of 6 months
    function getMonthsNewLock(uint32 lockedAt, uint32 duration) public view returns (uint256) {
        // If Lock is already expired return 0
        if (uint256(lockedAt + duration) <= block.timestamp) return 0;

        uint256 diff = block.timestamp - lockedAt;
        // How many months were selected originally?
        uint256 selectedMonths = uint256(duration) / AVG_SECONDS_MONTH;

        // How many months have passed?
        uint256 monthDelta = diff / AVG_SECONDS_MONTH;
        uint256 remainingMonths = selectedMonths - monthDelta;

        // If the remaining months are < 6 than we default to 6
        return remainingMonths > 6 ? remainingMonths : 6;
    }

    function getOldLock(address owner, uint256 oldLockId) public view returns (uint256, uint32, uint32) {
        return oldLock.locksOf(owner, oldLockId);
    }

    /// @notice Return the cumulative amount migratable together with the longest duration
    /// @param guy the user with the existing veDOUGH lock
    /// @dev ignores expired locks.
    /// @dev returns Tuple containing:
    ///         1. `longestDuration` in seconds that DOUGH was locked for i.e 35 months in seconds
    ///         2. Cumulative `longestAmount` migrateable together
    ///         3. `longestIndex` representing the lockID of the longest lock duration. In the event of multiple locks with
    ///             the same duration, we use the first id that appears
    function getAmountAndLongestDuration(address guy) public view returns (uint32, uint256, uint256) {
        uint32 longestDuration = 0;
        uint256 longestAmount = 0;
        uint256 longestIndex = 0;
        for (uint32 index = 0; index < oldLock.getLocksOfLength(guy); index++) {
            (uint256 lockAmount, uint32 lockedAt, uint32 lockDuration) = getOldLock(guy, index);

            if (lockAmount == 0) continue;
            if (uint256(lockedAt + lockDuration) <= block.timestamp) continue;

            longestAmount += lockAmount;

            if (lockDuration > longestDuration) {
                longestDuration = lockDuration;
                longestIndex = index;
            }
        }

        return (longestDuration, longestAmount, longestIndex);
    }

    /// @notice Returns the single longest lock by duration in order of creation
    /// @param guy user to fetch locks for
    /// @dev skips empty locks and expired locks
    /// @dev if two locks have the same duration, the first one in order of creation will be user
    function getNextLongestLock(address guy) public view returns (uint256, uint32, uint32, uint256) {
        uint256 longestAmount;
        uint32 longestLockedAt;
        uint32 longestDuration;
        uint256 longestIndex;
        for (uint256 index = 0; index < oldLock.getLocksOfLength(guy); index++) {
            (uint256 lockAmount, uint32 lockedAt, uint32 lockDuration) = getOldLock(guy, index);

            if (lockAmount == 0) continue;
            if (uint256(lockedAt + lockDuration) <= block.timestamp) continue;
            if (lockDuration <= longestDuration) continue;

            longestAmount = lockAmount;
            longestDuration = lockDuration;
            longestLockedAt = lockedAt;
            longestIndex = index;
        }

        return (longestAmount, longestLockedAt, longestDuration, longestIndex);
    }

    function getRate(uint256 amount) public pure returns (uint256) {
        return amount / 100;
    }
}