// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "./interfaces/IBLXMRewardProvider.sol";
import "./BLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/SafeMath.sol";
import "./libraries/Math.sol";
import "./libraries/BLXMLibrary.sol";
import "./interfaces/IBLXMTreasury.sol";


contract BLXMRewardProvider is ReentrancyGuardUpgradeable, BLXMMultiOwnable, BLXMTreasuryManager, IBLXMRewardProvider {

    using SafeMath for uint;


    struct Field {
        uint32 syncHour; // at most sync once an hour
        uint totalAmount; // exclude extra amount
        uint pendingRewards;
        uint32 initialHour;
        uint16 lastSession;

        // days => session
        mapping(uint32 => uint16) daysToSession;

        // session => Period struct
        mapping(uint16 => Period) periods;

        // hours from the epoch => statistics
        mapping(uint32 => Statistics) dailyStatistics;
    }

    struct Period {
        uint amountPerHours;
        uint32 startHour; // include, timestamp in hour from initial hour
        uint32 endHour; // exclude, timestamp in hour from initial hour
    }

    struct Statistics {
        uint amountIn; // include extra amount
        uint amountOut;
        uint aggregatedRewards; // rewards / (amountIn - amountOut)
        uint32 next;
    }

    struct Position {
        uint amount;
        uint extraAmount;
        uint32 startHour; // include, hour from epoch, time to start calculating rewards
        uint32 endLocking; // exclude, hour from epoch, locked until this hour
    }

    Field private treasuryFields;

    // user address => idx => position
    mapping(address => Position[]) public override allPosition;

    // locked days => factor
    mapping(uint16 => uint) internal rewardFactor;


    modifier sync() {
        syncStatistics();
        _;
    }

    function updateRewardFactor(uint16 lockedDays, uint factor) public override onlyOwner returns (bool) {
        require(lockedDays != 0, 'ZERO_DAYS');
        require(factor == 0 || factor >= 10 ** decimals(), 'WRONG_FACTOR');
        uint oldFactor = rewardFactor[lockedDays];
        rewardFactor[lockedDays] = factor;

        emit UpdateRewardFactor(msg.sender, oldFactor, factor);
        return true;
    }

    function getRewardFactor(uint16 lockedDays) external override view returns (uint factor) {
        factor = rewardFactor[lockedDays];
    }

    function allPositionLength(address investor) public override view returns (uint) {
        return allPosition[investor].length;
    }

    // ** DO NOT CALL THIS FUNCTION AS A WRITE FUNCTION **
    function calcRewards(address investor, uint idx) external override sync returns (uint rewardAmount, bool isLocked) {
        require(idx < allPositionLength(investor), 'NO_POSITION');
        Position memory position = allPosition[investor][idx];
        (rewardAmount, isLocked) = _calcRewards(position);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function getDailyStatistics(uint32 hourFromEpoch) external view override returns (uint amountIn, uint amountOut, uint aggregatedRewards, uint32 next) {
        Statistics memory statistics = treasuryFields.dailyStatistics[hourFromEpoch];
        amountIn = statistics.amountIn;
        amountOut = statistics.amountOut;
        aggregatedRewards = statistics.aggregatedRewards;
        next = statistics.next;
    }

    function hoursToSession(uint32 hourFromEpoch) external override view returns (uint16 session) {
        uint32 initialHour = treasuryFields.initialHour;
        if (hourFromEpoch >= initialHour) {
            uint32 hour = hourFromEpoch - initialHour;
            session = treasuryFields.daysToSession[hour / 24];
        }
    }

    function getPeriods(uint16 session) external override view returns (uint amountPerHours, uint32 startHour, uint32 endHour) {
        Period storage period = treasuryFields.periods[session];
        amountPerHours = period.amountPerHours;

        uint32 initialHour = treasuryFields.initialHour;
        startHour = period.startHour;
        endHour = period.endHour;
        
        if (startHour != 0 || endHour != 0) {
            startHour += initialHour;
            endHour += initialHour;
        }
    }

    function getTreasuryFields() external view override returns(uint32 syncHour, uint totalAmount, uint pendingRewards, uint32 initialHour, uint16 lastSession) {
        syncHour = treasuryFields.syncHour;
        totalAmount = treasuryFields.totalAmount;
        pendingRewards = treasuryFields.pendingRewards;
        initialHour = treasuryFields.initialHour;
        lastSession = treasuryFields.lastSession;
    }

    // should sync statistics every time before amount or rewards change
    function syncStatistics() public override {
        uint32 currentHour = BLXMLibrary.currentHour();
        uint32 syncHour = treasuryFields.syncHour;

        if (syncHour < currentHour) {
            if (syncHour != 0) {
                _updateStatistics(syncHour, currentHour);
            }
            treasuryFields.syncHour = currentHour;
        }
    }

    function _addRewards(uint totalAmount, uint16 supplyDays) internal nonReentrant sync returns (uint amountPerHours) {
        require(totalAmount > 0 && supplyDays > 0, 'ZERO_REWARDS');

        uint16 lastSession = treasuryFields.lastSession;
        if (lastSession == 0) {
            treasuryFields.initialHour = BLXMLibrary.currentHour();
        }

        uint32 startHour = treasuryFields.periods[lastSession].endHour;
        uint32 endHour = startHour + (supplyDays * 24);

        lastSession += 1;
        treasuryFields.lastSession = lastSession;

        uint32 target = startHour / 24;
        uint32 i = endHour / 24;
        unchecked {
            while (i --> target) {
                // reverse mapping
                treasuryFields.daysToSession[i] = lastSession;
            }
        }

        amountPerHours = totalAmount / (supplyDays * 24);
        treasuryFields.periods[lastSession] = Period(amountPerHours, startHour, endHour);

        if (treasuryFields.pendingRewards != 0) {
            uint pendingRewards = treasuryFields.pendingRewards;
            treasuryFields.pendingRewards = 0;
            _arrangeFailedRewards(pendingRewards);
        }

        uint32 initialHour = treasuryFields.initialHour;
        _addRewards(totalAmount);
        emit AddRewards(msg.sender, initialHour + startHour, initialHour + endHour, amountPerHours);
    }

    // if (is locked) {
    //     (amount + extra amount) * (agg now - agg hour in)
    // } else {
    //     amount * (agg now - agg day in)
    //     extra amount * (agg end locking - agg hour in)
    // }
    function _calcRewards(Position memory position) internal view returns (uint rewardAmount, bool isLocked) {

        uint32 currentHour = BLXMLibrary.currentHour();
        require(treasuryFields.syncHour == currentHour, 'NOT_SYNC');

        if (currentHour < position.startHour) {
            return (0, true);
        }

        if (currentHour < position.endLocking) {
            isLocked = true;
        }

        uint amount = position.amount;
        uint extraAmount = position.extraAmount;
        
        uint aggNow = treasuryFields.dailyStatistics[currentHour].aggregatedRewards;
        uint aggStart = treasuryFields.dailyStatistics[position.startHour].aggregatedRewards;
        if (isLocked) {
            rewardAmount = amount.add(extraAmount).wmul(aggNow.sub(aggStart));
        } else {
            uint aggEnd = treasuryFields.dailyStatistics[position.endLocking].aggregatedRewards;
            if (extraAmount != 0) {
                rewardAmount = extraAmount.wmul(aggEnd.sub(aggStart));
            }
            rewardAmount = rewardAmount.add(amount.wmul(aggNow.sub(aggStart)));
        }
    }

    function _stake(address to, uint amount, uint16 lockedDays) internal nonReentrant sync {
        require(amount != 0, 'INSUFFICIENT_AMOUNT');
        uint256 _factor = rewardFactor[lockedDays];
        require(_factor != 0, 'NO_FACTOR');

        uint extraAmount = amount.wmul(_factor.sub(10 ** decimals()));

        uint32 startHour = BLXMLibrary.currentHour() + 1;
        uint32 endLocking = startHour + (lockedDays * 24);

        allPosition[to].push(Position(amount, extraAmount, startHour, endLocking));
        
        _updateAmount(startHour, amount.add(extraAmount), 0);
        if (extraAmount != 0) {
            _updateAmount(endLocking, 0, extraAmount);
        }

        treasuryFields.totalAmount = amount.add(treasuryFields.totalAmount);

        _notify(amount, to);
        emit Stake(msg.sender, amount, to);
        _emitAllPosition(to, allPositionLength(to) - 1);
    }

    function _withdraw(address to, uint amount, uint idx) internal nonReentrant sync returns (uint rewardAmount) {
        require(idx < allPositionLength(msg.sender), 'NO_POSITION');
        Position memory position = allPosition[msg.sender][idx];
        require(amount > 0 && amount <= position.amount, 'INSUFFICIENT_AMOUNT');

        // The start hour must be a full hour, 
        // when add and remove on the same hour, 
        // the next hour's amount should be subtracted.
        uint32 hour = BLXMLibrary.currentHour();
        hour = hour >= position.startHour ? hour : position.startHour;
        _updateAmount(hour, 0, amount);

        uint extraAmount = position.extraAmount * amount / position.amount;

        bool isLocked;
        (rewardAmount, isLocked) = _calcRewards(position);
        rewardAmount = rewardAmount * amount / position.amount;
        if (isLocked) {
            _arrangeFailedRewards(rewardAmount);
            rewardAmount = 0;
            _updateAmount(hour, 0, extraAmount);
            _updateAmount(position.endLocking, extraAmount, 0);
        }

        allPosition[msg.sender][idx].amount = position.amount.sub(amount);
        allPosition[msg.sender][idx].extraAmount = position.extraAmount.sub(extraAmount);
        
        uint _totalAmount = treasuryFields.totalAmount;
        treasuryFields.totalAmount = _totalAmount.sub(amount);

        _withdraw(msg.sender, amount, rewardAmount, to);
        emit Withdraw(msg.sender, amount, rewardAmount, to);
        _emitAllPosition(msg.sender, idx);
    }

    function _arrangeFailedRewards(uint rewardAmount) internal {
        if (rewardAmount == 0) {
            return;
        }
        uint32 initialHour = treasuryFields.initialHour;
        uint32 startHour = BLXMLibrary.currentHour() - initialHour;
        uint16 session = treasuryFields.daysToSession[startHour / 24];
        if (session == 0) {
            treasuryFields.pendingRewards += rewardAmount;
            return;
        }

        uint32 endHour = treasuryFields.periods[session].endHour;
        uint32 leftHour = endHour - startHour;
        uint amountPerHours = rewardAmount / leftHour;
        treasuryFields.periods[session].amountPerHours += amountPerHours;

        emit ArrangeFailedRewards(msg.sender, initialHour + startHour, initialHour + endHour, amountPerHours);
    }

    function _emitAllPosition(address owner, uint idx) internal {
        Position memory position = allPosition[owner][idx];
        emit AllPosition(owner, position.amount, position.extraAmount, position.startHour, position.endLocking, idx);
    }

    function _updateAmount(uint32 hour, uint amountIn, uint amountOut) internal {
        require(hour >= BLXMLibrary.currentHour(), 'DATA_FIXED');
        Statistics memory statistics = treasuryFields.dailyStatistics[hour];
        statistics.amountIn = statistics.amountIn.add(amountIn);
        statistics.amountOut = statistics.amountOut.add(amountOut);
        treasuryFields.dailyStatistics[hour] = statistics;
    }

    function _updateStatistics(uint32 fromHour, uint32 toHour) internal {
        Statistics storage statistics = treasuryFields.dailyStatistics[fromHour];
        uint amountIn = statistics.amountIn;
        uint amountOut = statistics.amountOut;
        uint aggregatedRewards = statistics.aggregatedRewards;
        uint32 prev = fromHour; // point to previous statistics
        while (fromHour < toHour) {
            uint amount = amountIn.sub(amountOut);
            uint rewards = treasuryFields.periods[treasuryFields.daysToSession[(fromHour - treasuryFields.initialHour) / 24]].amountPerHours;

            if (amount != 0) {
                aggregatedRewards = aggregatedRewards.add(rewards.wdiv(amount));
            }

            fromHour += 1;
            statistics = treasuryFields.dailyStatistics[fromHour];

            if (statistics.amountIn != 0 || statistics.amountOut != 0 || fromHour == toHour) {
                statistics.aggregatedRewards = aggregatedRewards;
                statistics.amountIn = amountIn = amountIn.add(statistics.amountIn);
                statistics.amountOut = amountOut = amountOut.add(statistics.amountOut);
                treasuryFields.dailyStatistics[prev].next = fromHour;
                prev = fromHour;

                emit SyncStatistics(msg.sender, amountIn, amountOut, aggregatedRewards, fromHour);
            }
        }
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}