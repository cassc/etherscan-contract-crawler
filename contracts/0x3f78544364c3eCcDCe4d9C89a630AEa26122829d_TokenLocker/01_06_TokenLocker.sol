// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "PrismaOwnable.sol";
import "SystemStart.sol";
import "IPrismaCore.sol";
import "IIncentiveVoting.sol";
import "IPrismaToken.sol";

/**
    @title Prisma Token Locker
    @notice PRISMA tokens can be locked in this contract to receive "lock weight",
            which is used within `AdminVoting` and `IncentiveVoting` to vote on
            core protocol operations.
 */
contract TokenLocker is PrismaOwnable, SystemStart {
    // The maximum number of weeks that tokens may be locked for. Also determines the maximum
    // number of active locks that a single account may open. Weight is calculated as:
    // `[balance] * [weeks to unlock]`. Weights are stored as `uint40` and balances as `uint32`,
    // so the max lock weeks cannot be greater than 256 or the system could break due to overflow.
    uint256 public constant MAX_LOCK_WEEKS = 52;

    // Multiplier applied during token deposits and withdrawals. A balance within this
    // contract corresponds to a deposit of `balance * lockToTokenRatio` tokens. Balances
    // in this contract are stored as `uint32`, so the invariant:
    //
    // `lockToken.totalSupply() <= type(uint32).max * lockToTokenRatio`
    //
    // cannot be violated or the system could break due to overflow.
    uint256 public immutable lockToTokenRatio;

    IPrismaToken public immutable lockToken;
    IIncentiveVoting public immutable incentiveVoter;
    IPrismaCore public immutable prismaCore;
    address public immutable deploymentManager;

    bool public penaltyWithdrawalsEnabled;
    uint256 public allowPenaltyWithdrawAfter;

    struct AccountData {
        // Currently locked balance. Each week the lock weight decays by this amount.
        uint32 locked;
        // Currently unlocked balance (from expired locks, can be withdrawn)
        uint32 unlocked;
        // Currently "frozen" balance. A frozen balance is equivalent to a `MAX_LOCK_WEEKS` lock,
        // where the lock weight does not decay weekly. An account may have a locked balance or a
        // frozen balance, never both at the same time.
        uint32 frozen;
        // Current week within `accountWeeklyUnlocks`. Lock durations decay as this value increases.
        uint16 week;
        // Array of bitfields, where each bit represents 1 week. A bit is set to true when the
        // account has a non-zero token balance unlocking in that week, and so a non-zero value
        // at the same index in `accountWeeklyUnlocks`. We use this bitarray to reduce gas costs
        // when iterating over the weekly unlocks.
        uint256[256] updateWeeks;
    }

    // structs used in function inputs
    struct LockData {
        uint256 amount;
        uint256 weeksToUnlock;
    }
    struct ExtendLockData {
        uint256 amount;
        uint256 currentWeeks;
        uint256 newWeeks;
    }

    // Rate at which the total lock weight decreases each week. The total decay rate may not
    // be equal to the total number of locked tokens, as it does not include frozen accounts.
    uint32 public totalDecayRate;
    // Current week within `totalWeeklyWeights` and `totalWeeklyUnlocks`. When up-to-date
    // this value is always equal to `getWeek()`
    uint16 public totalUpdatedWeek;

    // week -> total lock weight
    uint40[65535] totalWeeklyWeights;
    // week -> tokens to unlock in this week
    uint32[65535] totalWeeklyUnlocks;

    // account -> week -> lock weight
    mapping(address => uint40[65535]) accountWeeklyWeights;

    // account -> week -> token balance unlocking this week
    mapping(address => uint32[65535]) accountWeeklyUnlocks;

    // account -> primary account data structure
    mapping(address => AccountData) accountLockData;

    event LockCreated(address indexed account, uint256 amount, uint256 _weeks);
    event LockExtended(address indexed account, uint256 amount, uint256 _weeks, uint256 newWeeks);
    event LocksCreated(address indexed account, LockData[] newLocks);
    event LocksExtended(address indexed account, ExtendLockData[] locks);
    event LocksFrozen(address indexed account, uint256 amount);
    event LocksUnfrozen(address indexed account, uint256 amount);
    event LocksWithdrawn(address indexed account, uint256 withdrawn, uint256 penalty);

    constructor(
        address _prismaCore,
        IPrismaToken _token,
        IIncentiveVoting _voter,
        address _manager,
        uint256 _lockToTokenRatio
    ) SystemStart(_prismaCore) PrismaOwnable(_prismaCore) {
        lockToken = _token;
        incentiveVoter = _voter;
        prismaCore = IPrismaCore(_prismaCore);
        deploymentManager = _manager;

        lockToTokenRatio = _lockToTokenRatio;
    }

    modifier notFrozen(address account) {
        require(accountLockData[account].frozen == 0, "Lock is frozen");
        _;
    }

    function setAllowPenaltyWithdrawAfter(uint256 _timestamp) external returns (bool) {
        require(msg.sender == deploymentManager, "!deploymentManager");
        require(allowPenaltyWithdrawAfter == 0, "Already set");
        require(_timestamp > block.timestamp && _timestamp < block.timestamp + 13 weeks, "Invalid timestamp");
        allowPenaltyWithdrawAfter = _timestamp;
        return true;
    }

    /**
        @notice Allow or disallow early-exit of locks by paying a penalty
     */
    function setPenaltyWithdrawalsEnabled(bool _enabled) external onlyOwner returns (bool) {
        uint256 start = allowPenaltyWithdrawAfter;
        require(start != 0 && block.timestamp > start, "Not yet!");
        penaltyWithdrawalsEnabled = _enabled;
        return true;
    }

    /**
        @notice Get the balances currently held in this contract for an account
        @return locked balance which is currently locked or frozen
        @return unlocked expired lock balance which may be withdrawn
     */
    function getAccountBalances(address account) external view returns (uint256 locked, uint256 unlocked) {
        AccountData storage accountData = accountLockData[account];
        uint256 frozen = accountData.frozen;
        unlocked = accountData.unlocked;
        if (frozen > 0) {
            return (frozen, unlocked);
        }

        locked = accountData.locked;
        if (locked > 0) {
            uint32[65535] storage weeklyUnlocks = accountWeeklyUnlocks[account];
            uint256 accountWeek = accountData.week;
            uint256 systemWeek = getWeek();

            uint256 bitfield = accountData.updateWeeks[accountWeek / 256] >> (accountWeek % 256);

            while (accountWeek < systemWeek) {
                accountWeek++;
                if (accountWeek % 256 == 0) {
                    bitfield = accountData.updateWeeks[accountWeek / 256];
                } else {
                    bitfield = bitfield >> 1;
                }
                if (bitfield & uint256(1) == 1) {
                    uint256 u = weeklyUnlocks[accountWeek];
                    locked -= u;
                    unlocked += u;
                    if (locked == 0) break;
                }
            }
        }
        return (locked, unlocked);
    }

    /**
        @notice Get the current lock weight for an account
     */
    function getAccountWeight(address account) external view returns (uint256) {
        return getAccountWeightAt(account, getWeek());
    }

    /**
        @notice Get the lock weight for an account in a given week
     */
    function getAccountWeightAt(address account, uint256 week) public view returns (uint256) {
        if (week > getWeek()) return 0;
        uint32[65535] storage weeklyUnlocks = accountWeeklyUnlocks[account];
        uint40[65535] storage weeklyWeights = accountWeeklyWeights[account];
        AccountData storage accountData = accountLockData[account];

        uint256 accountWeek = accountData.week;
        if (accountWeek >= week) return weeklyWeights[week];

        uint256 locked = accountData.locked;
        uint256 weight = weeklyWeights[accountWeek];
        if (locked == 0 || accountData.frozen > 0) {
            return weight;
        }

        uint256 bitfield = accountData.updateWeeks[accountWeek / 256] >> (accountWeek % 256);
        while (accountWeek < week) {
            accountWeek++;
            weight -= locked;
            if (accountWeek % 256 == 0) {
                bitfield = accountData.updateWeeks[accountWeek / 256];
            } else {
                bitfield = bitfield >> 1;
            }
            if (bitfield & uint256(1) == 1) {
                uint256 amount = weeklyUnlocks[accountWeek];
                locked -= amount;
                if (locked == 0) break;
            }
        }
        return weight;
    }

    /**
        @notice Get data on an accounts's active token locks and frozen balance
        @param account Address to query data for
        @return lockData dynamic array of [weeks until expiration, balance of lock]
        @return frozenAmount total frozen balance
     */
    function getAccountActiveLocks(
        address account,
        uint256 minWeeks
    ) external view returns (LockData[] memory lockData, uint256 frozenAmount) {
        AccountData storage accountData = accountLockData[account];
        frozenAmount = accountData.frozen;
        if (frozenAmount == 0) {
            if (minWeeks == 0) minWeeks = 1;
            uint32[65535] storage unlocks = accountWeeklyUnlocks[account];

            uint256 systemWeek = getWeek();
            uint256 currentWeek = systemWeek + minWeeks;
            uint256 maxLockWeek = systemWeek + MAX_LOCK_WEEKS;

            uint256[] memory unlockWeeks = new uint256[](MAX_LOCK_WEEKS);
            uint256 bitfield = accountData.updateWeeks[currentWeek / 256] >> (currentWeek % 256);

            uint256 length;
            while (currentWeek <= maxLockWeek) {
                if (bitfield & uint256(1) == 1) {
                    unlockWeeks[length] = currentWeek;
                    length++;
                }
                currentWeek++;
                if (currentWeek % 256 == 0) {
                    bitfield = accountData.updateWeeks[currentWeek / 256];
                } else {
                    bitfield = bitfield >> 1;
                }
            }

            lockData = new LockData[](length);
            uint256 x = length;
            // increment i, decrement x so LockData is ordered from longest to shortest duration
            for (uint256 i = 0; x != 0; i++) {
                x--;
                uint256 idx = unlockWeeks[x];
                lockData[i] = LockData({ weeksToUnlock: idx - systemWeek, amount: unlocks[idx] });
            }
        }
        return (lockData, frozenAmount);
    }

    /**
        @notice Get withdrawal and penalty amounts when withdrawing locked tokens
        @param account Account that will withdraw locked tokens
        @param amountToWithdraw Desired withdrawal amount, divided by `lockToTokenRatio`
        @return amountWithdrawn Actual amount withdrawn. If `amountToWithdraw` exceeds the
                                max possible withdrawal, the return value is the max
                                amount received after paying the penalty.
        @return penaltyAmountPaid The amount paid in penalty to perform this withdrawal
     */
    function getWithdrawWithPenaltyAmounts(
        address account,
        uint256 amountToWithdraw
    ) external view returns (uint256 amountWithdrawn, uint256 penaltyAmountPaid) {
        AccountData storage accountData = accountLockData[account];
        uint32[65535] storage unlocks = accountWeeklyUnlocks[account];
        if (amountToWithdraw != type(uint256).max) amountToWithdraw *= lockToTokenRatio;

        // first we apply the unlocked balance without penalty
        uint256 unlocked = accountData.unlocked * lockToTokenRatio;
        if (unlocked >= amountToWithdraw) {
            return (amountToWithdraw, 0);
        }

        uint256 remaining = amountToWithdraw - unlocked;
        uint256 penaltyTotal;

        uint256 accountWeek = accountData.week;
        uint256 systemWeek = getWeek();
        uint256 offset = systemWeek - accountWeek;
        uint256 bitfield = accountData.updateWeeks[accountWeek / 256];

        // `weeksToUnlock < MAX_LOCK_WEEKS` stops iteration prior to the final week
        for (uint256 weeksToUnlock = 1; weeksToUnlock < MAX_LOCK_WEEKS; weeksToUnlock++) {
            accountWeek++;

            if (accountWeek % 256 == 0) {
                bitfield = accountData.updateWeeks[accountWeek / 256];
            }

            if ((bitfield >> (accountWeek % 256)) & uint256(1) == 1) {
                uint256 lockAmount = unlocks[accountWeek] * lockToTokenRatio;

                uint256 penaltyOnAmount = 0;
                if (accountWeek > systemWeek) {
                    // only apply the penalty if the lock has not expired
                    penaltyOnAmount = (lockAmount * (weeksToUnlock - offset)) / MAX_LOCK_WEEKS;
                }

                if (lockAmount - penaltyOnAmount > remaining) {
                    // after penalty, locked amount exceeds remaining required balance
                    // we can complete the withdrawal using only a portion of this lock
                    penaltyOnAmount =
                        (remaining * MAX_LOCK_WEEKS) /
                        (MAX_LOCK_WEEKS - (weeksToUnlock - offset)) -
                        remaining;
                    uint256 dust = ((penaltyOnAmount + remaining) % lockToTokenRatio);
                    if (dust > 0) penaltyOnAmount += lockToTokenRatio - dust;
                    penaltyTotal += penaltyOnAmount;
                    remaining = 0;
                } else {
                    // after penalty, locked amount does not exceed remaining required balance
                    // the entire lock must be used in the withdrawal
                    penaltyTotal += penaltyOnAmount;
                    remaining -= lockAmount - penaltyOnAmount;
                }

                if (remaining == 0) {
                    break;
                }
            }
        }
        amountToWithdraw -= remaining;
        return (amountToWithdraw, penaltyTotal);
    }

    /**
        @notice Get the current total lock weight
     */
    function getTotalWeight() external view returns (uint256) {
        return getTotalWeightAt(getWeek());
    }

    /**
        @notice Get the total lock weight for a given week
     */
    function getTotalWeightAt(uint256 week) public view returns (uint256) {
        uint256 systemWeek = getWeek();
        if (week > systemWeek) return 0;

        uint32 updatedWeek = totalUpdatedWeek;
        if (week <= updatedWeek) return totalWeeklyWeights[week];

        uint32 rate = totalDecayRate;
        uint40 weight = totalWeeklyWeights[updatedWeek];
        if (rate == 0 || updatedWeek >= systemWeek) {
            return weight;
        }

        while (updatedWeek < systemWeek) {
            updatedWeek++;
            weight -= rate;
            rate -= totalWeeklyUnlocks[updatedWeek];
        }
        return weight;
    }

    /**
        @notice Get the current lock weight for an account
        @dev Also updates local storage values for this account. Using
             this function over it's `view` counterpart is preferred for
             contract -> contract interactions.
     */
    function getAccountWeightWrite(address account) external returns (uint256) {
        return _weeklyWeightWrite(account);
    }

    /**
        @notice Get the current total lock weight
        @dev Also updates local storage values for total weights. Using
             this function over it's `view` counterpart is preferred for
             contract -> contract interactions.
     */
    function getTotalWeightWrite() public returns (uint256) {
        uint256 week = getWeek();
        uint32 rate = totalDecayRate;
        uint32 updatedWeek = totalUpdatedWeek;
        uint40 weight = totalWeeklyWeights[updatedWeek];

        if (weight == 0) {
            totalUpdatedWeek = uint16(week);
            return 0;
        }

        while (updatedWeek < week) {
            updatedWeek++;
            weight -= rate;
            totalWeeklyWeights[updatedWeek] = weight;
            rate -= totalWeeklyUnlocks[updatedWeek];
        }

        totalDecayRate = rate;
        totalUpdatedWeek = uint16(week);

        return weight;
    }

    /**
        @notice Deposit tokens into the contract to create a new lock.
        @dev A lock is created for a given number of weeks. Minimum 1, maximum `MAX_LOCK_WEEKS`.
             An account can have multiple locks active at the same time. The account's "lock weight"
             is calculated as the sum of [number of tokens] * [weeks until unlock] for all active
             locks. At the start of each new week, each lock's weeks until unlock is reduced by 1.
             Locks that reach 0 weeks no longer receive any weight, and tokens may be withdrawn by
             calling `withdrawExpiredLocks`.
        @param _account Address to create a new lock for (does not have to be the caller)
        @param _amount Amount of tokens to lock. This balance transfered from the caller.
        @param _weeks The number of weeks for the lock
     */
    function lock(address _account, uint256 _amount, uint256 _weeks) external returns (bool) {
        require(_weeks > 0, "Min 1 week");
        require(_amount > 0, "Amount must be nonzero");
        _lock(_account, _amount, _weeks);
        lockToken.transferToLocker(msg.sender, _amount * lockToTokenRatio);

        return true;
    }

    function _lock(address _account, uint256 _amount, uint256 _weeks) internal {
        require(_weeks <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");
        AccountData storage accountData = accountLockData[_account];

        uint256 accountWeight = _weeklyWeightWrite(_account);
        uint256 totalWeight = getTotalWeightWrite();
        uint256 systemWeek = getWeek();
        uint256 frozen = accountData.frozen;
        if (frozen > 0) {
            accountData.frozen = uint32(frozen + _amount);
            _weeks = MAX_LOCK_WEEKS;
        } else {
            // disallow a 1 week lock in the final 3 days of the week
            if (_weeks == 1 && block.timestamp % 1 weeks > 4 days) _weeks = 2;

            accountData.locked = uint32(accountData.locked + _amount);
            totalDecayRate = uint32(totalDecayRate + _amount);

            uint32[65535] storage unlocks = accountWeeklyUnlocks[_account];
            uint256 unlockWeek = systemWeek + _weeks;
            uint256 previous = unlocks[unlockWeek];

            // modify weekly unlocks and unlock bitfield
            unlocks[unlockWeek] = uint32(previous + _amount);
            totalWeeklyUnlocks[unlockWeek] += uint32(_amount);
            if (previous == 0) {
                uint256 idx = unlockWeek / 256;
                uint256 bitfield = accountData.updateWeeks[idx] | (uint256(1) << (unlockWeek % 256));
                accountData.updateWeeks[idx] = bitfield;
            }
        }

        // update and adjust account weight and decay rate
        accountWeeklyWeights[_account][systemWeek] = uint40(accountWeight + _amount * _weeks);
        // update and modify total weight
        totalWeeklyWeights[systemWeek] = uint40(totalWeight + _amount * _weeks);
        emit LockCreated(_account, _amount, _weeks);
    }

    /**
        @notice Extend the length of an existing lock.
        @param _amount Amount of tokens to extend the lock for. When the value given equals
                       the total size of the existing lock, the entire lock is moved.
                       If the amount is less, then the lock is effectively split into
                       two locks, with a portion of the balance extended to the new length
                       and the remaining balance at the old length.
        @param _weeks The number of weeks for the lock that is being extended.
        @param _newWeeks The number of weeks to extend the lock until.
     */
    function extendLock(
        uint256 _amount,
        uint256 _weeks,
        uint256 _newWeeks
    ) external notFrozen(msg.sender) returns (bool) {
        require(_weeks > 0, "Min 1 week");
        require(_newWeeks <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");
        require(_weeks < _newWeeks, "newWeeks must be greater than weeks");
        require(_amount > 0, "Amount must be nonzero");

        AccountData storage accountData = accountLockData[msg.sender];
        uint256 systemWeek = getWeek();
        uint256 increase = (_newWeeks - _weeks) * _amount;
        uint32[65535] storage unlocks = accountWeeklyUnlocks[msg.sender];

        // update and adjust account weight
        // current decay rate is unaffected when extending
        uint256 weight = _weeklyWeightWrite(msg.sender);
        accountWeeklyWeights[msg.sender][systemWeek] = uint40(weight + increase);

        // reduce account weekly unlock for previous week and modify bitfield
        uint256 changedWeek = systemWeek + _weeks;
        uint256 previous = unlocks[changedWeek];
        unlocks[changedWeek] = uint32(previous - _amount);
        totalWeeklyUnlocks[changedWeek] -= uint32(_amount);
        if (previous == _amount) {
            uint256 idx = changedWeek / 256;
            uint256 bitfield = accountData.updateWeeks[idx] & ~(uint256(1) << (changedWeek % 256));
            accountData.updateWeeks[idx] = bitfield;
        }

        // increase account weekly unlock for new week and modify bitfield
        changedWeek = systemWeek + _newWeeks;
        previous = unlocks[changedWeek];
        unlocks[changedWeek] = uint32(previous + _amount);
        totalWeeklyUnlocks[changedWeek] += uint32(_amount);
        if (previous == 0) {
            uint256 idx = changedWeek / 256;
            uint256 bitfield = accountData.updateWeeks[idx] | (uint256(1) << (changedWeek % 256));
            accountData.updateWeeks[idx] = bitfield;
        }

        // update and modify total weight
        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() + increase);
        emit LockExtended(msg.sender, _amount, _weeks, _newWeeks);

        return true;
    }

    /**
        @notice Deposit tokens into the contract to create multiple new locks.
        @param _account Address to create new locks for (does not have to be the caller)
        @param newLocks Array of [(amount, weeks), ...] where amount is the amount of
                        tokens to lock, and weeks is the number of weeks for the lock.
                        All tokens to be locked are transferred from the caller.
     */
    function lockMany(address _account, LockData[] calldata newLocks) external notFrozen(_account) returns (bool) {
        AccountData storage accountData = accountLockData[_account];
        uint32[65535] storage unlocks = accountWeeklyUnlocks[_account];

        // update account weight
        uint256 accountWeight = _weeklyWeightWrite(_account);
        uint256 systemWeek = getWeek();

        // copy maybe-updated bitfield entries to memory
        uint256[2] memory bitfield = [
            accountData.updateWeeks[systemWeek / 256],
            accountData.updateWeeks[(systemWeek / 256) + 1]
        ];

        uint256 increasedAmount;
        uint256 increasedWeight;

        // iterate new locks and store intermediate values in memory where possible
        uint256 length = newLocks.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = newLocks[i].amount;
            uint256 week = newLocks[i].weeksToUnlock;
            require(amount > 0, "Amount must be nonzero");
            require(week > 0, "Min 1 week");
            require(week <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");

            // disallow a 1 week lock in the final 3 days of the week
            if (week == 1 && block.timestamp % 1 weeks > 4 days) week = 2;

            increasedAmount += amount;
            increasedWeight += amount * week;

            uint256 unlockWeek = systemWeek + week;
            uint256 previous = unlocks[unlockWeek];
            unlocks[unlockWeek] = uint32(previous + amount);
            totalWeeklyUnlocks[unlockWeek] += uint32(amount);

            if (previous == 0) {
                uint256 idx = (unlockWeek / 256) - (systemWeek / 256);
                bitfield[idx] = bitfield[idx] | (uint256(1) << (unlockWeek % 256));
            }
        }

        // write updated bitfield to storage
        accountData.updateWeeks[systemWeek / 256] = bitfield[0];
        accountData.updateWeeks[(systemWeek / 256) + 1] = bitfield[1];

        lockToken.transferToLocker(msg.sender, increasedAmount * lockToTokenRatio);

        // update account and total weight / decay storage values
        accountWeeklyWeights[_account][systemWeek] = uint40(accountWeight + increasedWeight);
        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() + increasedWeight);

        accountData.locked = uint32(accountData.locked + increasedAmount);
        totalDecayRate = uint32(totalDecayRate + increasedAmount);
        emit LocksCreated(_account, newLocks);

        return true;
    }

    /**
        @notice Extend the length of multiple existing locks.
        @param newExtendLocks Array of [(amount, weeks, newWeeks), ...] where amount is the amount
                              of tokens to extend the lock for, weeks is the current number of weeks
                              for the lock that is being extended, and newWeeks is the number of weeks
                              to extend the lock until.
     */
    function extendMany(ExtendLockData[] calldata newExtendLocks) external notFrozen(msg.sender) returns (bool) {
        AccountData storage accountData = accountLockData[msg.sender];
        uint32[65535] storage unlocks = accountWeeklyUnlocks[msg.sender];

        // update account weight
        uint256 accountWeight = _weeklyWeightWrite(msg.sender);
        uint256 systemWeek = getWeek();

        // copy maybe-updated bitfield entries to memory
        uint256[2] memory bitfield = [
            accountData.updateWeeks[systemWeek / 256],
            accountData.updateWeeks[(systemWeek / 256) + 1]
        ];
        uint256 increasedWeight;

        // iterate extended locks and store intermediate values in memory where possible
        uint256 length = newExtendLocks.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = newExtendLocks[i].amount;
            uint256 oldWeeks = newExtendLocks[i].currentWeeks;
            uint256 newWeeks = newExtendLocks[i].newWeeks;

            require(oldWeeks > 0, "Min 1 week");
            require(newWeeks <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");
            require(oldWeeks < newWeeks, "newWeeks must be greater than weeks");
            require(amount > 0, "Amount must be nonzero");

            increasedWeight += (newWeeks - oldWeeks) * amount;

            // reduce account weekly unlock for previous week and modify bitfield
            oldWeeks += systemWeek;
            uint256 previous = unlocks[oldWeeks];
            unlocks[oldWeeks] = uint32(previous - amount);
            totalWeeklyUnlocks[oldWeeks] -= uint32(amount);
            if (previous == amount) {
                uint256 idx = (oldWeeks / 256) - (systemWeek / 256);
                bitfield[idx] = bitfield[idx] & ~(uint256(1) << (oldWeeks % 256));
            }

            // increase account weekly unlock for new week and modify bitfield
            newWeeks += systemWeek;
            previous = unlocks[newWeeks];
            unlocks[newWeeks] = uint32(previous + amount);
            totalWeeklyUnlocks[newWeeks] += uint32(amount);
            if (previous == 0) {
                uint256 idx = (newWeeks / 256) - (systemWeek / 256);
                bitfield[idx] = bitfield[idx] | (uint256(1) << (newWeeks % 256));
            }
        }

        // write updated bitfield to storage
        accountData.updateWeeks[systemWeek / 256] = bitfield[0];
        accountData.updateWeeks[(systemWeek / 256) + 1] = bitfield[1];

        accountWeeklyWeights[msg.sender][systemWeek] = uint40(accountWeight + increasedWeight);
        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() + increasedWeight);
        emit LocksExtended(msg.sender, newExtendLocks);

        return true;
    }

    /**
        @notice Freeze all locks for the caller
        @dev When an account's locks are frozen, the weeks-to-unlock does not decay.
             All other functionality remains the same; the account can continue to lock,
             extend locks, and withdraw tokens. Freezing greatly reduces gas costs for
             actions such as emissions voting.
     */
    function freeze() external notFrozen(msg.sender) {
        AccountData storage accountData = accountLockData[msg.sender];
        uint32[65535] storage unlocks = accountWeeklyUnlocks[msg.sender];

        uint256 accountWeight = _weeklyWeightWrite(msg.sender);
        uint256 totalWeight = getTotalWeightWrite();

        // remove account locked balance from the total decay rate
        uint256 locked = accountData.locked;
        require(locked > 0, "No locked balance");
        totalDecayRate = uint32(totalDecayRate - locked);
        accountData.frozen = uint32(locked);
        accountData.locked = 0;

        uint256 systemWeek = getWeek();
        accountWeeklyWeights[msg.sender][systemWeek] = uint40(locked * MAX_LOCK_WEEKS);
        totalWeeklyWeights[systemWeek] = uint40(totalWeight - accountWeight + locked * MAX_LOCK_WEEKS);

        // use bitfield to iterate acount unlocks and subtract them from the total unlocks
        uint256 bitfield = accountData.updateWeeks[systemWeek / 256] >> (systemWeek % 256);
        while (locked > 0) {
            systemWeek++;
            if (systemWeek % 256 == 0) {
                bitfield = accountData.updateWeeks[systemWeek / 256];
                accountData.updateWeeks[(systemWeek / 256) - 1] = 0;
            } else {
                bitfield = bitfield >> 1;
            }
            if (bitfield & uint256(1) == 1) {
                uint32 amount = unlocks[systemWeek];
                unlocks[systemWeek] = 0;
                totalWeeklyUnlocks[systemWeek] -= amount;
                locked -= amount;
            }
        }
        accountData.updateWeeks[systemWeek / 256] = 0;
        emit LocksFrozen(msg.sender, locked);
    }

    /**
        @notice Unfreeze all locks for the caller
        @dev When an account's locks are unfrozen, the weeks-to-unlock decay normally.
             This is the default locking behaviour for each account. Unfreezing locks
             also updates the frozen status within `IncentiveVoter` - otherwise it could be
             possible for accounts to have a larger registered vote weight than their actual
             lock weight.
        @param keepIncentivesVote If true, existing incentive votes are preserved when updating
                                  the frozen status within `IncentiveVoter`. Voting with unfrozen
                                  weight uses significantly more gas than voting with frozen weight.
                                  If the caller has many active locks and/or many votes, it will be
                                  much cheaper to set this value to false.

     */
    function unfreeze(bool keepIncentivesVote) external {
        AccountData storage accountData = accountLockData[msg.sender];
        uint32[65535] storage unlocks = accountWeeklyUnlocks[msg.sender];
        uint256 frozen = accountData.frozen;
        require(frozen > 0, "Locks already unfrozen");

        // unfreeze the caller's registered vote weights
        incentiveVoter.unfreeze(msg.sender, keepIncentivesVote);

        // update account weights and get the current account week
        _weeklyWeightWrite(msg.sender);
        getTotalWeightWrite();

        // add account decay to the total decay rate
        totalDecayRate = uint32(totalDecayRate + frozen);
        accountData.locked = uint32(frozen);
        accountData.frozen = 0;

        uint256 systemWeek = getWeek();

        uint256 unlockWeek = systemWeek + MAX_LOCK_WEEKS;

        // modify weekly unlocks and unlock bitfield
        unlocks[unlockWeek] = uint32(frozen);
        totalWeeklyUnlocks[unlockWeek] += uint32(frozen);
        uint256 idx = unlockWeek / 256;
        uint256 bitfield = accountData.updateWeeks[idx] | (uint256(1) << (unlockWeek % 256));
        accountData.updateWeeks[idx] = bitfield;
        emit LocksUnfrozen(msg.sender, frozen);
    }

    /**
        @notice Withdraw tokens from locks that have expired
        @param _weeks Optional number of weeks for the re-locking.
                      If 0 the full amount is transferred back to the user.

     */
    function withdrawExpiredLocks(uint256 _weeks) external returns (bool) {
        _weeklyWeightWrite(msg.sender);
        getTotalWeightWrite();

        AccountData storage accountData = accountLockData[msg.sender];
        uint256 unlocked = accountData.unlocked;
        require(unlocked > 0, "No unlocked tokens");
        accountData.unlocked = 0;
        if (_weeks > 0) {
            _lock(msg.sender, unlocked, _weeks);
        } else {
            lockToken.transfer(msg.sender, unlocked * lockToTokenRatio);
            emit LocksWithdrawn(msg.sender, unlocked, 0);
        }
        return true;
    }

    /**
        @notice Pay a penalty to withdraw locked tokens
        @dev Withdrawals are processed starting with the lock that will expire soonest.
             The penalty starts at 100% and decays linearly based on the number of weeks
             remaining until the tokens unlock. The exact calculation used is:

             [total amount] * [weeks to unlock] / MAX_LOCK_WEEKS = [penalty amount]

        @param amountToWithdraw Amount to withdraw, divided by `lockToTokenRatio`. This
                                is the same number of tokens that will be received; the
                                penalty amount is taken on top of this. Reverts if the
                                caller's locked balances are insufficient to cover both
                                the withdrawal and penalty amounts. Setting this value as
                                `type(uint256).max` withdrawals the entire available locked
                                balance, excluding any lock at `MAX_LOCK_WEEKS` as the
                                penalty on this lock would be 100%.
        @return uint256 Amount of tokens withdrawn
     */
    function withdrawWithPenalty(uint256 amountToWithdraw) external notFrozen(msg.sender) returns (uint256) {
        require(penaltyWithdrawalsEnabled, "Penalty withdrawals are disabled");
        AccountData storage accountData = accountLockData[msg.sender];
        uint32[65535] storage unlocks = accountWeeklyUnlocks[msg.sender];
        uint256 weight = _weeklyWeightWrite(msg.sender);
        if (amountToWithdraw != type(uint256).max) amountToWithdraw *= lockToTokenRatio;

        // start by withdrawing unlocked balance without penalty
        uint256 unlocked = accountData.unlocked * lockToTokenRatio;
        if (unlocked >= amountToWithdraw) {
            accountData.unlocked = uint32((unlocked - amountToWithdraw) / lockToTokenRatio);
            lockToken.transfer(msg.sender, amountToWithdraw);
            return amountToWithdraw;
        }

        // clear the caller's registered vote weight
        incentiveVoter.clearRegisteredWeight(msg.sender);

        uint256 remaining = amountToWithdraw;
        if (unlocked > 0) {
            remaining -= unlocked;
            accountData.unlocked = 0;
        }

        uint256 systemWeek = getWeek();
        uint256 bitfield = accountData.updateWeeks[systemWeek / 256];
        uint256 penaltyTotal;
        uint256 decreasedWeight;

        // `weeksToUnlock < MAX_LOCK_WEEKS` stops iteration prior to the final week
        for (uint256 weeksToUnlock = 1; weeksToUnlock < MAX_LOCK_WEEKS; weeksToUnlock++) {
            systemWeek++;
            if (systemWeek % 256 == 0) {
                accountData.updateWeeks[systemWeek / 256 - 1] = 0;
                bitfield = accountData.updateWeeks[systemWeek / 256];
            }

            if ((bitfield >> (systemWeek % 256)) & uint256(1) == 1) {
                uint256 lockAmount = unlocks[systemWeek] * lockToTokenRatio;
                uint256 penaltyOnAmount = (lockAmount * weeksToUnlock) / MAX_LOCK_WEEKS;

                if (lockAmount - penaltyOnAmount > remaining) {
                    // after penalty, locked amount exceeds remaining required balance
                    // we can complete the withdrawal using only a portion of this lock
                    penaltyOnAmount = (remaining * MAX_LOCK_WEEKS) / (MAX_LOCK_WEEKS - weeksToUnlock) - remaining;
                    uint256 dust = ((penaltyOnAmount + remaining) % lockToTokenRatio);
                    if (dust > 0) penaltyOnAmount += lockToTokenRatio - dust;
                    penaltyTotal += penaltyOnAmount;
                    uint256 lockReduceAmount = (penaltyOnAmount + remaining) / lockToTokenRatio;
                    decreasedWeight += lockReduceAmount * weeksToUnlock;
                    unlocks[systemWeek] -= uint32(lockReduceAmount);
                    totalWeeklyUnlocks[systemWeek] -= uint32(lockReduceAmount);
                    remaining = 0;
                } else {
                    // after penalty, locked amount does not exceed remaining required balance
                    // the entire lock must be used in the withdrawal
                    penaltyTotal += penaltyOnAmount;
                    decreasedWeight += (lockAmount / lockToTokenRatio) * weeksToUnlock;
                    bitfield = bitfield & ~(uint256(1) << (systemWeek % 256));
                    unlocks[systemWeek] = 0;
                    totalWeeklyUnlocks[systemWeek] -= uint32(lockAmount / lockToTokenRatio);
                    remaining -= lockAmount - penaltyOnAmount;
                }

                if (remaining == 0) {
                    break;
                }
            }
        }

        accountData.updateWeeks[systemWeek / 256] = bitfield;

        if (amountToWithdraw == type(uint256).max) {
            amountToWithdraw -= remaining;
        } else {
            require(remaining == 0, "Insufficient balance after fees");
        }

        accountData.locked -= uint32((amountToWithdraw + penaltyTotal - unlocked) / lockToTokenRatio);
        totalDecayRate -= uint32((amountToWithdraw + penaltyTotal - unlocked) / lockToTokenRatio);
        systemWeek = getWeek();
        accountWeeklyWeights[msg.sender][systemWeek] = uint40(weight - decreasedWeight);
        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() - decreasedWeight);

        lockToken.transfer(msg.sender, amountToWithdraw);
        lockToken.transfer(prismaCore.feeReceiver(), penaltyTotal);
        emit LocksWithdrawn(msg.sender, amountToWithdraw, penaltyTotal);

        return amountToWithdraw;
    }

    /**
        @dev Updates all data for a given account and returns the account's current weight and week
     */
    function _weeklyWeightWrite(address account) internal returns (uint256 weight) {
        AccountData storage accountData = accountLockData[account];
        uint32[65535] storage weeklyUnlocks = accountWeeklyUnlocks[account];
        uint40[65535] storage weeklyWeights = accountWeeklyWeights[account];

        uint256 systemWeek = getWeek();
        uint256 accountWeek = accountData.week;
        weight = weeklyWeights[accountWeek];
        if (accountWeek == systemWeek) return weight;

        if (accountData.frozen > 0) {
            while (systemWeek > accountWeek) {
                accountWeek++;
                weeklyWeights[accountWeek] = uint40(weight);
            }
            accountData.week = uint16(systemWeek);
            return weight;
        }

        // if account is not frozen and locked balance is 0, we only need to update the account week
        uint256 locked = accountData.locked;
        if (locked == 0) {
            if (accountWeek < systemWeek) {
                accountData.week = uint16(systemWeek);
            }
            return 0;
        }

        uint256 unlocked;
        uint256 bitfield = accountData.updateWeeks[accountWeek / 256] >> (accountWeek % 256);

        while (accountWeek < systemWeek) {
            accountWeek++;
            weight -= locked;
            weeklyWeights[accountWeek] = uint40(weight);
            if (accountWeek % 256 == 0) {
                bitfield = accountData.updateWeeks[accountWeek / 256];
            } else {
                bitfield = bitfield >> 1;
            }
            if (bitfield & uint256(1) == 1) {
                uint32 amount = weeklyUnlocks[accountWeek];
                locked -= amount;
                unlocked += amount;
                if (locked == 0) {
                    // if locked balance hits 0, there are no further tokens to unlock
                    accountWeek = systemWeek;
                    break;
                }
            }
        }

        accountData.unlocked = uint32(accountData.unlocked + unlocked);
        accountData.locked = uint32(locked);
        accountData.week = uint16(accountWeek);
        return weight;
    }
}