// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "DelegatedOps.sol";
import "SystemStart.sol";
import "ITokenLocker.sol";

/**
    @title Prisma Incentive Voting
    @notice Users with PRISMA balances locked in `TokenLocker` may register their
            lock weights in this contract, and use this weight to vote on where
            new PRISMA emissions will be released in the following week.

            Conceptually, incentive voting functions similarly to Curve's gauge weight voting.
 */
contract IncentiveVoting is DelegatedOps, SystemStart {
    uint256 public constant MAX_POINTS = 10000; // must be less than 2**16 or things will break
    uint256 public constant MAX_LOCK_WEEKS = 52; // must be the same as `MultiLocker`

    ITokenLocker public immutable tokenLocker;
    address public immutable vault;

    struct AccountData {
        // system week when the account's lock weights were registered
        // used to offset `weeksToUnlock` when calculating vote weight
        // as it decays over time
        uint16 week;
        // total registered vote weight, only recorded when frozen.
        // for unfrozen weight, recording the total is unnecessary because the
        // value decays. throughout the code, we check if frozenWeight > 0 as
        // a way to indicate if a lock is frozen.
        uint40 frozenWeight;
        uint16 points;
        uint8 lockLength; // length of weeksToUnlock and lockedAmounts
        uint16 voteLength; // length of activeVotes
        // array of [(receiver id, points), ... ] stored as uint16[2] for optimal packing
        uint16[2][MAX_POINTS] activeVotes;
        // arrays map to one another: lockedAmounts[0] unlocks in weeksToUnlock[0] weeks
        // values are sorted by time-to-unlock descending
        uint32[MAX_LOCK_WEEKS] lockedAmounts;
        uint8[MAX_LOCK_WEEKS] weeksToUnlock;
    }

    struct Vote {
        uint256 id;
        uint256 points;
    }

    struct LockData {
        uint256 amount;
        uint256 weeksToUnlock;
    }

    mapping(address => AccountData) accountLockData;

    uint256 public receiverCount;
    // id -> receiver data
    uint32[65535] public receiverDecayRate;
    uint16[65535] public receiverUpdatedWeek;
    // id -> week -> absolute vote weight
    uint40[65535][65535] receiverWeeklyWeights;
    // id -> week -> registered lock weight that is lost
    uint32[65535][65535] public receiverWeeklyUnlocks;

    uint32 public totalDecayRate;
    uint16 public totalUpdatedWeek;
    uint40[65535] totalWeeklyWeights;
    uint32[65535] public totalWeeklyUnlocks;

    // emitted each time an account's lock weight is registered
    event AccountWeightRegistered(
        address indexed account,
        uint256 indexed week,
        uint256 frozenBalance,
        ITokenLocker.LockData[] registeredLockData
    );
    // emitted each time an account submits one or more new votes. only includes
    // vote points for the current call, for a complete list of an account's votes
    // you must join all instances of this event that fired more recently than the
    // latest `ClearedVotes` for the the same account.
    event NewVotes(address indexed account, uint256 indexed week, Vote[] newVotes, uint256 totalPointsUsed);
    // emitted each time the votes for `account` are cleared
    event ClearedVotes(address indexed account, uint256 indexed week);

    constructor(address _prismaCore, ITokenLocker _tokenLocker, address _vault) SystemStart(_prismaCore) {
        tokenLocker = _tokenLocker;
        vault = _vault;
    }

    function getAccountRegisteredLocks(
        address account
    ) external view returns (uint256 frozenWeight, LockData[] memory lockData) {
        return (accountLockData[account].frozenWeight, _getAccountLocks(account));
    }

    function getAccountCurrentVotes(address account) public view returns (Vote[] memory votes) {
        votes = new Vote[](accountLockData[account].voteLength);
        uint16[2][MAX_POINTS] storage storedVotes = accountLockData[account].activeVotes;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            votes[i] = Vote({ id: storedVotes[i][0], points: storedVotes[i][1] });
        }
        return votes;
    }

    function getReceiverWeight(uint256 idx) external view returns (uint256) {
        return getReceiverWeightAt(idx, getWeek());
    }

    function getReceiverWeightAt(uint256 idx, uint256 week) public view returns (uint256) {
        if (idx >= receiverCount) return 0;
        uint256 rate = receiverDecayRate[idx];
        uint256 updatedWeek = receiverUpdatedWeek[idx];
        if (week <= updatedWeek) return receiverWeeklyWeights[idx][week];

        uint256 weight = receiverWeeklyWeights[idx][updatedWeek];
        if (weight == 0) return 0;

        while (updatedWeek < week) {
            updatedWeek++;
            weight -= rate;
            rate -= receiverWeeklyUnlocks[idx][updatedWeek];
        }

        return weight;
    }

    function getTotalWeight() external view returns (uint256) {
        return getTotalWeightAt(getWeek());
    }

    function getTotalWeightAt(uint256 week) public view returns (uint256) {
        uint256 rate = totalDecayRate;
        uint256 updatedWeek = totalUpdatedWeek;
        if (week <= updatedWeek) return totalWeeklyWeights[week];

        uint256 weight = totalWeeklyWeights[updatedWeek];
        if (weight == 0) return 0;

        while (updatedWeek < week) {
            updatedWeek++;
            weight -= rate;
            rate -= totalWeeklyUnlocks[updatedWeek];
        }
        return weight;
    }

    function getReceiverWeightWrite(uint256 idx) public returns (uint256) {
        require(idx < receiverCount, "Invalid ID");
        uint256 week = getWeek();
        uint256 updatedWeek = receiverUpdatedWeek[idx];
        uint256 weight = receiverWeeklyWeights[idx][updatedWeek];

        if (weight == 0) {
            receiverUpdatedWeek[idx] = uint16(week);
            return 0;
        }

        uint256 rate = receiverDecayRate[idx];
        while (updatedWeek < week) {
            updatedWeek++;
            weight -= rate;
            receiverWeeklyWeights[idx][updatedWeek] = uint40(weight);
            rate -= receiverWeeklyUnlocks[idx][updatedWeek];
        }

        receiverDecayRate[idx] = uint32(rate);
        receiverUpdatedWeek[idx] = uint16(week);

        return weight;
    }

    function getTotalWeightWrite() public returns (uint256) {
        uint256 week = getWeek();
        uint256 updatedWeek = totalUpdatedWeek;
        uint256 weight = totalWeeklyWeights[updatedWeek];

        if (weight == 0) {
            totalUpdatedWeek = uint16(week);
            return 0;
        }

        uint256 rate = totalDecayRate;
        while (updatedWeek < week) {
            updatedWeek++;
            weight -= rate;
            totalWeeklyWeights[updatedWeek] = uint40(weight);
            rate -= totalWeeklyUnlocks[updatedWeek];
        }

        totalDecayRate = uint32(rate);
        totalUpdatedWeek = uint16(week);

        return weight;
    }

    function getReceiverVotePct(uint256 id, uint256 week) external returns (uint256) {
        week -= 1;
        getReceiverWeightWrite(id);
        getTotalWeightWrite();

        uint256 totalWeight = totalWeeklyWeights[week];
        if (totalWeight == 0) return 0;

        return (1e18 * uint256(receiverWeeklyWeights[id][week])) / totalWeight;
    }

    function registerNewReceiver() external returns (uint256) {
        require(msg.sender == vault, "Not Treasury");
        uint256 id = receiverCount;
        receiverUpdatedWeek[id] = uint16(getWeek());
        receiverCount = id + 1;
        return id;
    }

    /**
        @notice Record the current lock weights for `account`, which can then
                be used to vote.
        @param minWeeks The minimum number of weeks-to-unlock to record weights
                        for. The more active lock weeks that are registered, the
                        more expensive it will be to vote. Accounts with many active
                        locks may wish to skip smaller locks to reduce gas costs.
     */
    function registerAccountWeight(address account, uint256 minWeeks) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];
        Vote[] memory existingVotes;

        // if account has an active vote, clear the recorded vote
        // weights prior to updating the registered account weights
        if (accountData.voteLength > 0) {
            existingVotes = getAccountCurrentVotes(account);
            _removeVoteWeights(account, existingVotes, accountData.frozenWeight);
        }

        // get updated account lock weights and store locally
        uint256 frozenWeight = _registerAccountWeight(account, minWeeks);

        // resubmit the account's active vote using the newly registered weights
        _addVoteWeights(account, existingVotes, frozenWeight);
        // do not call `_storeAccountVotes` because the vote is unchanged
    }

    /**
        @notice Record the current lock weights for `account` and submit new votes
        @dev New votes replace any prior active votes
        @param minWeeks Minimum number of weeks-to-unlock to record weights for
        @param votes Array of tuples of (recipient id, vote points)
     */
    function registerAccountWeightAndVote(
        address account,
        uint256 minWeeks,
        Vote[] calldata votes
    ) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];

        // if account has an active vote, clear the recorded vote
        // weights prior to updating the registered account weights
        if (accountData.voteLength > 0) {
            _removeVoteWeights(account, getAccountCurrentVotes(account), accountData.frozenWeight);
            emit ClearedVotes(account, getWeek());
        }

        // get updated account lock weights and store locally
        uint256 frozenWeight = _registerAccountWeight(account, minWeeks);

        // adjust vote weights based on the account's new vote
        _addVoteWeights(account, votes, frozenWeight);
        // store the new account votes
        _storeAccountVotes(account, accountData, votes, 0, 0);
    }

    /**
        @notice Vote for one or more recipients
        @dev * Each voter can vote with up to `MAX_POINTS` points
             * It is not required to use every point in a single call
             * Votes carry over week-to-week and decay at the same rate as lock
               weight
             * The total weight is NOT distributed porportionally based on the
               points used, an account must allocate all points in order to use
               it's full vote weight
        @param votes Array of tuples of (recipient id, vote points)
        @param clearPrevious if true, the voter's current votes are cleared
                             prior to recording the new votes. If false, new
                             votes are added in addition to previous votes.
     */
    function vote(address account, Vote[] calldata votes, bool clearPrevious) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];
        uint256 frozenWeight = accountData.frozenWeight;
        require(frozenWeight > 0 || accountData.lockLength > 0, "No registered weight");
        uint256 points;
        uint256 offset;

        // optionally clear previous votes
        if (clearPrevious) {
            _removeVoteWeights(account, getAccountCurrentVotes(account), frozenWeight);
            emit ClearedVotes(account, getWeek());
        } else {
            points = accountData.points;
            offset = accountData.voteLength;
        }

        // adjust vote weights based on the new vote
        _addVoteWeights(account, votes, frozenWeight);
        // store the new account votes
        _storeAccountVotes(account, accountData, votes, points, offset);
    }

    /**
        @notice Remove all active votes for the caller
     */
    function clearVote(address account) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];
        uint256 frozenWeight = accountData.frozenWeight;
        _removeVoteWeights(account, getAccountCurrentVotes(account), frozenWeight);
        accountData.voteLength = 0;
        accountData.points = 0;

        emit ClearedVotes(account, getWeek());
    }

    /**
        @notice Clear registered weight and votes for `account`
        @dev Called by `tokenLocker` when an account performs an early withdrawal
             of locked tokens, to prevent a registered weight > actual lock weight
     */
    function clearRegisteredWeight(address account) external returns (bool) {
        require(
            msg.sender == account || msg.sender == address(tokenLocker) || isApprovedDelegate[account][msg.sender],
            "Delegate not approved"
        );

        AccountData storage accountData = accountLockData[account];
        uint256 week = getWeek();
        uint256 length = accountData.lockLength;
        uint256 frozenWeight = accountData.frozenWeight;
        if (length > 0 || frozenWeight > 0) {
            if (accountData.voteLength > 0) {
                _removeVoteWeights(account, getAccountCurrentVotes(account), frozenWeight);
                accountData.voteLength = 0;
                accountData.points = 0;
                emit ClearedVotes(account, week);
            }
            // lockLength and frozenWeight are never both > 0
            if (length > 0) accountData.lockLength = 0;
            else accountData.frozenWeight = 0;

            emit AccountWeightRegistered(account, week, 0, new ITokenLocker.LockData[](0));
        }

        return true;
    }

    /**
        @notice Set a frozen account weight as unfrozen
        @dev Callable only by the token locker. This prevents users from
             registering frozen locks, unfreezing, and having a larger registered
             vote weight than their actual lock weight.
     */
    function unfreeze(address account, bool keepVote) external returns (bool) {
        require(msg.sender == address(tokenLocker));
        AccountData storage accountData = accountLockData[account];
        uint256 frozenWeight = accountData.frozenWeight;

        // if frozenWeight == 0, the account was not registered so nothing needed
        if (frozenWeight > 0) {
            // clear previous votes
            Vote[] memory existingVotes;
            if (accountData.voteLength > 0) {
                existingVotes = getAccountCurrentVotes(account);
                _removeVoteWeightsFrozen(existingVotes, frozenWeight);
            }

            uint256 week = getWeek();
            accountData.week = uint16(week);
            accountData.frozenWeight = 0;

            uint amount = frozenWeight / MAX_LOCK_WEEKS;
            accountData.lockedAmounts[0] = uint32(amount);
            accountData.weeksToUnlock[0] = uint8(MAX_LOCK_WEEKS);
            accountData.lockLength = 1;

            // optionally resubmit previous votes
            if (existingVotes.length > 0) {
                if (keepVote) {
                    _addVoteWeightsUnfrozen(account, existingVotes);
                } else {
                    accountData.voteLength = 0;
                    accountData.points = 0;
                    emit ClearedVotes(account, week);
                }
            }

            ITokenLocker.LockData[] memory lockData = new ITokenLocker.LockData[](1);
            lockData[0] = ITokenLocker.LockData({ amount: amount, weeksToUnlock: MAX_LOCK_WEEKS });
            emit AccountWeightRegistered(account, week, 0, lockData);
        }
        return true;
    }

    /**
        @dev Get the current registered lock weights for `account`, as an array
             of [(amount, weeks to unlock)] sorted by weeks-to-unlock descending.
     */
    function _getAccountLocks(address account) internal view returns (LockData[] memory lockData) {
        AccountData storage accountData = accountLockData[account];

        uint256 length = accountData.lockLength;
        uint256 systemWeek = getWeek();
        uint256 accountWeek = accountData.frozenWeight > 0 ? systemWeek : accountData.week;
        uint8[MAX_LOCK_WEEKS] storage weeksToUnlock = accountData.weeksToUnlock;
        uint32[MAX_LOCK_WEEKS] storage amounts = accountData.lockedAmounts;

        lockData = new LockData[](length);
        uint256 idx;
        for (; idx < length; idx++) {
            uint256 unlockWeek = weeksToUnlock[idx] + accountWeek;
            if (unlockWeek <= systemWeek) {
                assembly {
                    mstore(lockData, idx)
                }
                break;
            }
            uint256 remainingWeeks = unlockWeek - systemWeek;
            uint256 amount = amounts[idx];
            lockData[idx] = LockData({ amount: amount, weeksToUnlock: remainingWeeks });
        }

        return lockData;
    }

    function _registerAccountWeight(address account, uint256 minWeeks) internal returns (uint256) {
        AccountData storage accountData = accountLockData[account];

        // get updated account lock weights and store locally
        (ITokenLocker.LockData[] memory lockData, uint256 frozen) = tokenLocker.getAccountActiveLocks(
            account,
            minWeeks
        );
        uint256 length = lockData.length;
        if (frozen > 0) {
            frozen *= MAX_LOCK_WEEKS;
            accountData.frozenWeight = uint40(frozen);
        } else if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 amount = lockData[i].amount;
                uint256 weeksToUnlock = lockData[i].weeksToUnlock;
                accountData.lockedAmounts[i] = uint32(amount);
                accountData.weeksToUnlock[i] = uint8(weeksToUnlock);
            }
        } else {
            revert("No active locks");
        }
        uint256 week = getWeek();
        accountData.week = uint16(week);
        accountData.lockLength = uint8(length);

        emit AccountWeightRegistered(account, week, frozen, lockData);

        return frozen;
    }

    function _storeAccountVotes(
        address account,
        AccountData storage accountData,
        Vote[] calldata votes,
        uint256 points,
        uint256 offset
    ) internal {
        uint16[2][MAX_POINTS] storage storedVotes = accountData.activeVotes;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            storedVotes[offset + i] = [uint16(votes[i].id), uint16(votes[i].points)];
            points += votes[i].points;
        }
        require(points <= MAX_POINTS, "Exceeded max vote points");
        accountData.voteLength = uint16(offset + length);
        accountData.points = uint16(points);

        emit NewVotes(account, getWeek(), votes, points);
    }

    /**
        @dev Increases receiver and total weights, using a vote array and the
             registered weights of `msg.sender`. Account related values are not
             adjusted, they must be handled in the calling function.
     */
    function _addVoteWeights(address account, Vote[] memory votes, uint256 frozenWeight) internal {
        if (votes.length > 0) {
            if (frozenWeight > 0) {
                _addVoteWeightsFrozen(votes, frozenWeight);
            } else {
                _addVoteWeightsUnfrozen(account, votes);
            }
        }
    }

    /**
        @dev Decreases receiver and total weights, using a vote array and the
             registered weights of `msg.sender`. Account related values are not
             adjusted, they must be handled in the calling function.
     */
    function _removeVoteWeights(address account, Vote[] memory votes, uint256 frozenWeight) internal {
        if (votes.length > 0) {
            if (frozenWeight > 0) {
                _removeVoteWeightsFrozen(votes, frozenWeight);
            } else {
                _removeVoteWeightsUnfrozen(account, votes);
            }
        }
    }

    /** @dev Should not be called directly, use `_addVoteWeights` */
    function _addVoteWeightsUnfrozen(address account, Vote[] memory votes) internal {
        LockData[] memory lockData = _getAccountLocks(account);
        uint256 lockLength = lockData.length;
        require(lockLength > 0, "Registered weight has expired");

        uint256 totalWeight;
        uint256 totalDecay;
        uint256 systemWeek = getWeek();
        uint256[MAX_LOCK_WEEKS + 1] memory weeklyUnlocks;
        for (uint256 i = 0; i < votes.length; i++) {
            uint256 id = votes[i].id;
            uint256 points = votes[i].points;

            uint256 weight = 0;
            uint256 decayRate = 0;
            for (uint256 x = 0; x < lockLength; x++) {
                uint256 weeksToUnlock = lockData[x].weeksToUnlock;
                uint256 amount = (lockData[x].amount * points) / MAX_POINTS;
                receiverWeeklyUnlocks[id][systemWeek + weeksToUnlock] += uint32(amount);

                weeklyUnlocks[weeksToUnlock] += uint32(amount);
                weight += amount * weeksToUnlock;
                decayRate += amount;
            }
            receiverWeeklyWeights[id][systemWeek] = uint40(getReceiverWeightWrite(id) + weight);
            receiverDecayRate[id] += uint32(decayRate);

            totalWeight += weight;
            totalDecay += decayRate;
        }

        for (uint256 i = 0; i < lockLength; i++) {
            uint256 weeksToUnlock = lockData[i].weeksToUnlock;
            totalWeeklyUnlocks[systemWeek + weeksToUnlock] += uint32(weeklyUnlocks[weeksToUnlock]);
        }
        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() + totalWeight);
        totalDecayRate += uint32(totalDecay);
    }

    /** @dev Should not be called directly, use `_addVoteWeights` */
    function _addVoteWeightsFrozen(Vote[] memory votes, uint256 frozenWeight) internal {
        uint256 systemWeek = getWeek();
        uint256 totalWeight;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id = votes[i].id;
            uint256 points = votes[i].points;

            uint256 weight = (frozenWeight * points) / MAX_POINTS;

            receiverWeeklyWeights[id][systemWeek] = uint40(getReceiverWeightWrite(id) + weight);
            totalWeight += weight;
        }

        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() + totalWeight);
    }

    /** @dev Should not be called directly, use `_removeVoteWeights` */
    function _removeVoteWeightsUnfrozen(address account, Vote[] memory votes) internal {
        LockData[] memory lockData = _getAccountLocks(account);
        uint256 lockLength = lockData.length;

        uint256 totalWeight;
        uint256 totalDecay;
        uint256 systemWeek = getWeek();
        uint256[MAX_LOCK_WEEKS + 1] memory weeklyUnlocks;

        for (uint256 i = 0; i < votes.length; i++) {
            (uint256 id, uint256 points) = (votes[i].id, votes[i].points);

            uint256 weight = 0;
            uint256 decayRate = 0;
            for (uint256 x = 0; x < lockLength; x++) {
                uint256 weeksToUnlock = lockData[x].weeksToUnlock;
                uint256 amount = (lockData[x].amount * points) / MAX_POINTS;
                receiverWeeklyUnlocks[id][systemWeek + weeksToUnlock] -= uint32(amount);

                weeklyUnlocks[weeksToUnlock] += uint32(amount);
                weight += amount * weeksToUnlock;
                decayRate += amount;
            }
            receiverWeeklyWeights[id][systemWeek] = uint40(getReceiverWeightWrite(id) - weight);
            receiverDecayRate[id] -= uint32(decayRate);

            totalWeight += weight;
            totalDecay += decayRate;
        }

        for (uint256 i = 0; i < lockLength; i++) {
            uint256 weeksToUnlock = lockData[i].weeksToUnlock;
            totalWeeklyUnlocks[systemWeek + weeksToUnlock] -= uint32(weeklyUnlocks[weeksToUnlock]);
        }
        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() - totalWeight);
        totalDecayRate -= uint32(totalDecay);
    }

    /** @dev Should not be called directly, use `_removeVoteWeights` */
    function _removeVoteWeightsFrozen(Vote[] memory votes, uint256 frozenWeight) internal {
        uint256 systemWeek = getWeek();

        uint256 totalWeight;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            (uint256 id, uint256 points) = (votes[i].id, votes[i].points);

            uint256 weight = (frozenWeight * points) / MAX_POINTS;

            receiverWeeklyWeights[id][systemWeek] = uint40(getReceiverWeightWrite(id) - weight);

            totalWeight += weight;
        }

        totalWeeklyWeights[systemWeek] = uint40(getTotalWeightWrite() - totalWeight);
    }
}