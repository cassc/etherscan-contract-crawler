// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

import "../interfaces/ILockTOSv2Action0.sol";
import "../interfaces/ITOS.sol";
import "../libraries/LibLockTOS.sol";
import "../common/AccessibleCommon.sol";
import "./LockTOSStorage.sol";
import "./ProxyBase.sol";
import "./LockTOSv2Storage.sol";

// import "hardhat/console.log";

interface MyTreasury {
    function isTreasury() external view returns (bool);
}

contract LockTOSv2Logic0 is
    LockTOSStorage,
    AccessibleCommon,
    ProxyBase,
    LockTOSv2Storage,
    ILockTOSv2Action0
{
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;

    event LockCreated(
        address account,
        uint256 lockId,
        uint256 value,
        uint256 unlockTime
    );
    event LockAmountIncreased(address account, uint256 lockId, uint256 value);
    event LockUnlockTimeIncreased(
        address account,
        uint256 lockId,
        uint256 unlockTime
    );
    event LockDeposited(address account, uint256 lockId, uint256 value);
    event LockWithdrawn(address account, uint256 lockId, uint256 value);


    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

    /// @inheritdoc ILockTOSv2Action0
    function needCheckpoint() external view override returns (bool need) {
        uint256 len = pointHistory.length;
        if (len == 0) {
            return true;
        }
        need = (block.timestamp - pointHistory[len - 1].timestamp) > epochUnit; // if the last record was within a week
    }

    /// @inheritdoc ILockTOSv2Action0
    function setMaxTime(uint256 _maxTime) external override onlyOwner {
        maxTime = _maxTime;
    }

    /// @inheritdoc ILockTOSv2Action0
    function transferTosToTreasury(address _treasury) external  override onlyOwner {
        require(_treasury != address(0), "zero address");
        require(MyTreasury(_treasury).isTreasury(), "not treasury");

        IERC20(tos).transfer(_treasury, IERC20(tos).balanceOf(address(this)));
    }

    /// @inheritdoc ILockTOSv2Action0
    function setStaker(address _staker) external  override onlyOwner {
        require(_staker != address(0), "zero address");
        require(staker != _staker, "same address");
        staker = _staker;
    }

    /// @inheritdoc ILockTOSv2Action0
    function allHolders() external view override returns (address[] memory) {
        return uniqueUsers;
    }

    /// @inheritdoc ILockTOSv2Action0
    function activeHolders() external view override returns (address[] memory) {
        bool[] memory activeCheck = new bool[](uniqueUsers.length);
        uint256 activeSize = 0;
        for (uint256 i = 0; i < uniqueUsers.length; ++i) {
            uint256[] memory activeLocks = activeLocksOf(uniqueUsers[i]);
            if (activeLocks.length > 0) {
                activeSize++;
                activeCheck[i] = true;
            }
        }

        address[] memory activeUsers = new address[](activeSize);
        uint256 j = 0;
        for (uint256 i = 0; i < uniqueUsers.length; ++i) {
            if (activeCheck[i]) {
                activeUsers[j++] = uniqueUsers[i];
            }
        }
        return activeUsers;
    }

    /// @inheritdoc ILockTOSv2Action0
    function increaseAmountByStaker(address user, uint256 _lockId, uint256 _value) external override onlyStaker {
        depositFor(user, _lockId, _value);
    }

    function increaseAmountOfIds(
        address[] memory users,
        uint256[] memory _lockIds,
        uint256[] memory _values,
        uint256 curTime
    )
        external onlyOwner
    {
        require(
            users.length > 0
            && users.length ==  _lockIds.length
            && users.length ==  _values.length ,
            "wrong length"
        );

        uint256 len = users.length;
        //console.log("increaseAmountOfIds len %s", len);

        for (uint256 i = 0; i < len; i++){
            address _account = users[i];
            uint256 _id = _lockIds[i];
            uint256 _value = _values[i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_account][_id];
            if (lock.withdrawn == false  && _value > 0) {
                //console.log("increaseAmountOfIds _id %s , _value %s", _id, _value);

                cumulativeTOSAmount.add(_value);

                // ==========================

                LibLockTOS.LockedBalance memory lockedOld = lock;
                LibLockTOS.LockedBalance memory lockedNew =
                    LibLockTOS.LockedBalance({
                        amount: lockedOld.amount,
                        start: lockedOld.start,
                        end: lockedOld.end,
                        withdrawn: false
                    });

                // Make new lock
                lockedNew.amount = lockedNew.amount.add(_value);

                // Checkpoint
                _checkpointForSync(lockedNew, lockedOld, curTime);

                // Save new lock
                lockedBalances[_account][_id] = lockedNew;
                allLocks[_id] = lockedNew;
                //console.log("Save new lock _id %s ", _id);

                // Save user point,
                int256 userSlope = lockedNew.amount.mul(MULTIPLIER).div(maxTime).toInt256();
                int256 userBias = userSlope.mul(lockedNew.end.sub(curTime).toInt256());
                LibLockTOS.Point memory userPoint =
                    LibLockTOS.Point({
                        timestamp: curTime,
                        slope: userSlope,
                        bias: userBias
                    });
                lockPointHistory[_id].push(userPoint);
                // ==========================
                // emit LockDeposited(_account, _id, _value);
            }
        }

    }

    /// @inheritdoc ILockTOSv2Action0
    function increaseUnlockTimeByStaker(address user, uint256 _lockId, uint256 _unlockWeeks)
        external override
        onlyStaker
    {
        require(_unlockWeeks > 0, "Unlock period less than a week");
        cumulativeEpochUnit = cumulativeEpochUnit.add(_unlockWeeks);

        LibLockTOS.LockedBalance memory lock =
            lockedBalances[user][_lockId];
        uint256 unlockTime = lock.end.add(_unlockWeeks.mul(epochUnit));
        unlockTime = unlockTime.div(epochUnit).mul(epochUnit);
        require(
            unlockTime - block.timestamp < maxTime,
            "Max unlock time is 3 years"
        );
        require(lock.end > block.timestamp, "Lock time already finished");
        require(lock.end < unlockTime, "New lock time must be greater");
        require(lock.amount > 0, "No existing locked TOS");
        _deposit(user, _lockId, 0, unlockTime);

        emit LockUnlockTimeIncreased(user, _lockId, unlockTime);
    }

    /// @inheritdoc ILockTOSv2Action0
    function increaseAmountUnlockTimeByStaker(address user, uint256 _lockId, uint256 _value, uint256 _unlockWeeks)
        external override onlyStaker
    {
        // console.log("increaseAmountUnlockTimeByStaker in ");
        require(_value > 0, "Value locked should be non-zero");
        require(_unlockWeeks > 0, "Unlock period less than a week");

        LibLockTOS.LockedBalance memory lock = lockedBalances[user][_lockId];
        require(lock.withdrawn == false, "Lock is withdrawn");
        require(lock.start > 0, "Lock does not exist");
        require(lock.end > block.timestamp, "Lock time is finished");

        uint256 unlockTime = lock.end.add(_unlockWeeks.mul(epochUnit));
        unlockTime = unlockTime.div(epochUnit).mul(epochUnit);
        require(
            unlockTime - block.timestamp < maxTime,
            "Max unlock time is 3 years"
        );
        require(lock.end < unlockTime, "New lock time must be greater");
        require(lock.amount > 0, "No existing locked TOS");

        cumulativeTOSAmount = cumulativeTOSAmount.add(_value);
        cumulativeEpochUnit = cumulativeEpochUnit.add(_unlockWeeks);

        _deposit(user, _lockId, _value, unlockTime);

        emit LockDeposited(user, _lockId, _value);
        emit LockUnlockTimeIncreased(user, _lockId, unlockTime);
    }



    /// @inheritdoc ILockTOSv2Action0
    function withdrawAllByStaker(address user) external override ifFree onlyStaker{
        uint256[] storage locks = userLocks[user];
        if (locks.length == 0) {
            return;
        }

        for (uint256 i = 0; i < locks.length; i++) {
            LibLockTOS.LockedBalance memory lock = allLocks[locks[i]];
            if (
                lock.withdrawn == false &&
                locks[i] > 0 &&
                lock.amount > 0 &&
                lock.start > 0 &&
                lock.end > 0 &&
                lock.end < block.timestamp
            ) {
                _withdraw(user, locks[i]);
            }
        }
    }

    /// @inheritdoc ILockTOSv2Action0
    function globalCheckpoint() external  override {
        _recordHistoryPoints();
    }

    /// @inheritdoc ILockTOSv2Action0
    function withdrawByStaker(address user, uint256 _lockId) public override ifFree onlyStaker {
        require(_lockId > 0, "_lockId is zero");
        _withdraw(user, _lockId);
    }

    function _withdraw(address user, uint256 _lockId) internal {
        LibLockTOS.LockedBalance memory lockedOld =
            lockedBalances[user][_lockId];
        require(lockedOld.withdrawn == false, "Already withdrawn");
        require(lockedOld.start > 0, "Lock does not exist");
        require(lockedOld.end < block.timestamp, "Lock time not finished");
        require(lockedOld.amount > 0, "No amount to withdraw");

        LibLockTOS.LockedBalance memory lockedNew =
            LibLockTOS.LockedBalance({
                amount: 0,
                start: 0,
                end: 0,
                withdrawn: true
            });

        // Checkpoint
        _checkpoint(lockedNew, lockedOld);

        // Transfer TOS back
        uint256 amount = lockedOld.amount;
        lockedBalances[user][_lockId] = lockedNew;
        allLocks[_lockId] = lockedNew;

        // IERC20(tos).transfer(user, amount);
        emit LockWithdrawn(user, _lockId, amount);
    }

    /// @inheritdoc ILockTOSv2Action0
    function createLockByStaker(address user, uint256 _value, uint256 _unlockWeeks)
        public override
        onlyStaker
        returns (uint256 lockId)
    {
        require(_value > 0, "Value locked should be non-zero");
        require(_unlockWeeks > 0, "Unlock period less than a week");

        cumulativeEpochUnit = cumulativeEpochUnit.add(_unlockWeeks);
        cumulativeTOSAmount = cumulativeTOSAmount.add(_value);
        uint256 unlockTime = block.timestamp.add(_unlockWeeks.mul(epochUnit));
        unlockTime = unlockTime.div(epochUnit).mul(epochUnit);
        require(
            unlockTime - block.timestamp <= maxTime,
            "Max unlock time is 3 years"
        );

        if (userLocks[user].length == 0) { // check if user for the first time
            uniqueUsers.push(user);
        }

        lockIdCounter = lockIdCounter.add(1);
        lockId = lockIdCounter;

        _deposit(user, lockId, _value, unlockTime);
        userLocks[user].push(lockId);

        emit LockCreated(user, lockId, _value, unlockTime);
    }

    /// @inheritdoc ILockTOSv2Action0
    function depositFor(
        address _addr,
        uint256 _lockId,
        uint256 _value
    ) public override onlyStaker {
        require(_value > 0, "Value locked should be non-zero");
        LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][_lockId];
        require(lock.withdrawn == false, "Lock is withdrawn");
        require(lock.start > 0, "Lock does not exist");
        require(lock.end > block.timestamp, "Lock time is finished");

        cumulativeTOSAmount = cumulativeTOSAmount.add(_value);
        _deposit(_addr, _lockId, _value, 0);
        emit LockDeposited(_addr, _lockId, _value);
    }

    /// @inheritdoc ILockTOSv2Action0
    function totalSupplyAt(uint256 _timestamp)
        public
        view override
        returns (uint256)
    {
        if (pointHistory.length == 0) {
            return 0;
        }

        (bool success, LibLockTOS.Point memory point) =
            _findClosestPoint(pointHistory, _timestamp);
        if (!success) {
            return 0;
        }

        point = _fillRecordGaps(point, _timestamp);
        int256 currentBias =
            point.slope * (_timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias - currentBias : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOSv2Action0
    function totalLockedAmountOf(address _addr) external view override returns (uint256) {
        uint256 len = userLocks[_addr].length;
        uint256 stakedAmount = 0;
        for (uint256 i = 0; i < len; ++i) {
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            stakedAmount = stakedAmount.add(lock.amount);
        }
        return stakedAmount;
    }

    /// @inheritdoc ILockTOSv2Action0
    function withdrawableAmountOf(address _addr) external view override returns (uint256) {
        uint256 len = userLocks[_addr].length;
        uint256 amount = 0;
        for(uint i = 0; i < len; i++){
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end <= block.timestamp && lock.amount > 0 && lock.withdrawn == false) {
                amount = amount.add(lock.amount);
            }
        }
        return amount;
    }

    /// @inheritdoc ILockTOSv2Action0
    function totalSupply() external view override returns (uint256) {
        if (pointHistory.length == 0) {
            return 0;
        }

        LibLockTOS.Point memory point = _fillRecordGaps(
            pointHistory[pointHistory.length - 1],
            block.timestamp
        );

        int256 currentBias =
            point.slope.mul(block.timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias.sub(currentBias) : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOSv2Action0
    function balanceOfLockAt(uint256 _lockId, uint256 _timestamp)
        public override
        view
        returns (uint256)
    {
        (bool success, LibLockTOS.Point memory point) =
            _findClosestPoint(lockPointHistory[_lockId], _timestamp);
        if (!success) {
            return 0;
        }
        int256 currentBias =
            point.slope.mul(_timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias.sub(currentBias) : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOSv2Action0
    function balanceOfLock(uint256 _lockId)
        public override
        view
        returns (uint256)
    {
        uint256 len = lockPointHistory[_lockId].length;
        if (len == 0) {
            return 0;
        }

        LibLockTOS.Point memory point = lockPointHistory[_lockId][len - 1];
        int256 currentBias =
            point.slope.mul(block.timestamp.sub(point.timestamp).toInt256());
        return
            uint256(point.bias > currentBias ? point.bias.sub(currentBias) : 0)
                .div(MULTIPLIER);
    }

    /// @inheritdoc ILockTOSv2Action0
    function balanceOfAt(address _addr, uint256 _timestamp)
        public override
        view
        returns (uint256 balance)
    {
        uint256[] memory locks = userLocks[_addr];
        if (locks.length == 0) return 0;
        for (uint256 i = 0; i < locks.length; ++i) {
            balance = balance.add(balanceOfLockAt(locks[i], _timestamp));
        }
    }

    /// @inheritdoc ILockTOSv2Action0
    function balanceOf(address _addr)
        public override
        view
        returns (uint256 balance)
    {
        uint256[] memory locks = userLocks[_addr];
        if (locks.length == 0) return 0;
        for (uint256 i = 0; i < locks.length; ++i) {
            balance = balance.add(balanceOfLock(locks[i]));
        }
    }

    /// @inheritdoc ILockTOSv2Action0
    function locksInfo(uint256 _lockId)
        public override
        view
        returns (
            uint256 start,
            uint256 end,
            uint256 amount
        )
    {
        return (
            allLocks[_lockId].start,
            allLocks[_lockId].end,
            allLocks[_lockId].amount
        );
    }

    /// @inheritdoc ILockTOSv2Action0
    function locksOf(address _addr)
        public override
        view
        returns (uint256[] memory)
    {
        return userLocks[_addr];
    }

    /// @inheritdoc ILockTOSv2Action0
    function withdrawableLocksOf(address _addr)  external view override onlyStaker returns (uint256[] memory) {
        uint256 len = userLocks[_addr].length;
        uint256 size = 0;
        for(uint i = 0; i < len; i++){
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end <= block.timestamp && lock.amount > 0 && lock.withdrawn == false) {
                size++;
            }
        }

        uint256[] memory withdrawable = new uint256[](size);
        size = 0;
        for(uint i = 0; i < len; i++) {
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end <= block.timestamp && lock.amount > 0 && lock.withdrawn == false) {
                withdrawable[size++] = lockId;
            }
        }
        return withdrawable;
    }

    /// @inheritdoc ILockTOSv2Action0
    function activeLocksOf(address _addr)
        public
        view override
        returns (uint256[] memory)
    {
        uint256 len = userLocks[_addr].length;
        uint256 _size = 0;
        for(uint i = 0; i < len; i++){
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end > block.timestamp) {
                _size++;
            }
        }

        uint256[] memory activeLocks = new uint256[](_size);
        _size = 0;
        for(uint i = 0; i < len; i++) {
            uint256 lockId = userLocks[_addr][i];
            LibLockTOS.LockedBalance memory lock = lockedBalances[_addr][lockId];
            if(lock.end > block.timestamp) {
                activeLocks[_size++] = lockId;
            }
        }
        return activeLocks;
    }

    /// @inheritdoc ILockTOSv2Action0
    function pointHistoryOf(uint256 _lockId)
        public
        view override
        returns (LibLockTOS.Point[] memory)
    {
        return lockPointHistory[_lockId];
    }


    function _findClosestPoint(
        LibLockTOS.Point[] storage _history,
        uint256 _timestamp
    ) internal view returns (bool success, LibLockTOS.Point memory point) {
        if (_history.length == 0) {
            return (false, point);
        }

        uint256 left = 0;
        uint256 right = _history.length;
        while (left + 1 < right) {
            uint256 mid = left.add(right).div(2);
            if (_history[mid].timestamp <= _timestamp) {
                left = mid;
            } else {
                right = mid;
            }
        }

        if (_history[left].timestamp <= _timestamp) {
            return (true, _history[left]);
        }
        return (false, point);
    }


    function _deposit(
        address _addr,
        uint256 _lockId,
        uint256 _value,
        uint256 _unlockTime
    ) internal ifFree {
        LibLockTOS.LockedBalance memory lockedOld =
            lockedBalances[_addr][_lockId];
        LibLockTOS.LockedBalance memory lockedNew =
            LibLockTOS.LockedBalance({
                amount: lockedOld.amount,
                start: lockedOld.start,
                end: lockedOld.end,
                withdrawn: false
            });

        // Make new lock
        lockedNew.amount = lockedNew.amount.add(_value);
        if (_unlockTime > 0) {
            lockedNew.end = _unlockTime;
        }
        if (lockedNew.start == 0) {
            lockedNew.start = block.timestamp;
        }

        // Checkpoint
        _checkpoint(lockedNew, lockedOld);

        // Save new lock
        lockedBalances[_addr][_lockId] = lockedNew;
        allLocks[_lockId] = lockedNew;

        // Save user point,
        int256 userSlope =
            lockedNew.amount.mul(MULTIPLIER).div(maxTime).toInt256();
        int256 userBias =
            userSlope.mul(lockedNew.end.sub(block.timestamp).toInt256());
        LibLockTOS.Point memory userPoint =
            LibLockTOS.Point({
                timestamp: block.timestamp,
                slope: userSlope,
                bias: userBias
            });
        lockPointHistory[_lockId].push(userPoint);

        // Transfer TOS
        // require(
        //     IERC20(tos).transferFrom(_addr, address(this), _value),
        //     "LockTOS: fail transferFrom"
        // );
    }

    function _checkpointForSync(
        LibLockTOS.LockedBalance memory lockedNew,
        LibLockTOS.LockedBalance memory lockedOld,
        uint256 curTime
    ) internal {
        uint256 timestamp = curTime;
        LibLockTOS.SlopeChange memory changeNew =
            LibLockTOS.SlopeChange({slope: 0, bias: 0, changeTime: 0});
        LibLockTOS.SlopeChange memory changeOld =
            LibLockTOS.SlopeChange({slope: 0, bias: 0, changeTime: 0});

        // Initialize slope changes
        if (lockedNew.end > timestamp && lockedNew.amount > 0) {
            changeNew.slope = lockedNew
                .amount
                .mul(MULTIPLIER)
                .div(maxTime)
                .toInt256();
            changeNew.bias = changeNew.slope
                .mul(lockedNew.end.sub(timestamp).toInt256());
            changeNew.changeTime = lockedNew.end;
        }
        if (lockedOld.end > timestamp && lockedOld.amount > 0) {
            changeOld.slope = lockedOld
                .amount
                .mul(MULTIPLIER)
                .div(maxTime)
                .toInt256();
            changeOld.bias = changeOld.slope
                .mul(lockedOld.end.sub(timestamp).toInt256());
            changeOld.changeTime = lockedOld.end;
        }

        // Record history gaps
        LibLockTOS.Point memory currentWeekPoint = _recordHistoryPoints();
        currentWeekPoint.bias = currentWeekPoint.bias.add(
            changeNew.bias.sub(changeOld.bias)
        );
        currentWeekPoint.slope = currentWeekPoint.slope.add(
            changeNew.slope.sub(changeOld.slope)
        );
        currentWeekPoint.bias = currentWeekPoint.bias > 0
            ? currentWeekPoint.bias
            : 0;
        currentWeekPoint.slope = currentWeekPoint.slope > 0
            ? currentWeekPoint.slope
            : 0;
        pointHistory[pointHistory.length - 1] = currentWeekPoint;

        // Update slope changes
        _updateSlopeChangesForSync(changeNew, changeOld, curTime);
    }

    function _updateSlopeChangesForSync(
        LibLockTOS.SlopeChange memory changeNew,
        LibLockTOS.SlopeChange memory changeOld,
        uint256 curTIme
    ) internal {
        int256 deltaSlopeNew = slopeChanges[changeNew.changeTime];
        int256 deltaSlopeOld = slopeChanges[changeOld.changeTime];
        if (changeOld.changeTime > curTIme) {
            deltaSlopeOld = deltaSlopeOld.add(changeOld.slope);
            if (changeOld.changeTime == changeNew.changeTime) {
                deltaSlopeOld = deltaSlopeOld.sub(changeNew.slope);
            }
            slopeChanges[changeOld.changeTime] = deltaSlopeOld;
        }
        if (
            changeNew.changeTime > curTIme &&
            changeNew.changeTime > changeOld.changeTime
        ) {
            deltaSlopeNew = deltaSlopeNew.sub(changeNew.slope);
            slopeChanges[changeNew.changeTime] = deltaSlopeNew;
        }
    }

    function _checkpoint(
        LibLockTOS.LockedBalance memory lockedNew,
        LibLockTOS.LockedBalance memory lockedOld
    ) internal {
        uint256 timestamp = block.timestamp;
        LibLockTOS.SlopeChange memory changeNew =
            LibLockTOS.SlopeChange({slope: 0, bias: 0, changeTime: 0});
        LibLockTOS.SlopeChange memory changeOld =
            LibLockTOS.SlopeChange({slope: 0, bias: 0, changeTime: 0});

        // Initialize slope changes
        if (lockedNew.end > timestamp && lockedNew.amount > 0) {
            changeNew.slope = lockedNew
                .amount
                .mul(MULTIPLIER)
                .div(maxTime)
                .toInt256();
            changeNew.bias = changeNew.slope
                .mul(lockedNew.end.sub(timestamp).toInt256());
            changeNew.changeTime = lockedNew.end;
        }
        if (lockedOld.end > timestamp && lockedOld.amount > 0) {
            changeOld.slope = lockedOld
                .amount
                .mul(MULTIPLIER)
                .div(maxTime)
                .toInt256();
            changeOld.bias = changeOld.slope
                .mul(lockedOld.end.sub(timestamp).toInt256());
            changeOld.changeTime = lockedOld.end;
        }

        // Record history gaps
        LibLockTOS.Point memory currentWeekPoint = _recordHistoryPoints();
        currentWeekPoint.bias = currentWeekPoint.bias.add(
            changeNew.bias.sub(changeOld.bias)
        );
        currentWeekPoint.slope = currentWeekPoint.slope.add(
            changeNew.slope.sub(changeOld.slope)
        );
        currentWeekPoint.bias = currentWeekPoint.bias > 0
            ? currentWeekPoint.bias
            : 0;
        currentWeekPoint.slope = currentWeekPoint.slope > 0
            ? currentWeekPoint.slope
            : 0;
        pointHistory[pointHistory.length - 1] = currentWeekPoint;

        // Update slope changes
        _updateSlopeChanges(changeNew, changeOld);
    }


    function _recordHistoryPoints()
        internal
        returns (LibLockTOS.Point memory lastWeek)
    {
        uint256 timestamp = block.timestamp;
        if (pointHistory.length > 0) {
            lastWeek = pointHistory[pointHistory.length - 1];
        } else {
            lastWeek = LibLockTOS.Point({
                bias: 0,
                slope: 0,
                timestamp: timestamp
            });
        }

        // Iterate through all past unrecoreded weeks and record
        uint256 pointTimestampIterator =
            lastWeek.timestamp.div(epochUnit).mul(epochUnit);
        while (pointTimestampIterator != timestamp) {
            pointTimestampIterator = Math.min(
                pointTimestampIterator.add(epochUnit),
                timestamp
            );
            int256 deltaSlope = slopeChanges[pointTimestampIterator];
            int256 deltaTime =
                Math.min(pointTimestampIterator.sub(lastWeek.timestamp), epochUnit).toInt256();
            lastWeek.bias = lastWeek.bias.sub(lastWeek.slope.mul(deltaTime));
            lastWeek.slope = lastWeek.slope.add(deltaSlope);
            lastWeek.bias = lastWeek.bias > 0 ? lastWeek.bias : 0;
            lastWeek.slope = lastWeek.slope > 0 ? lastWeek.slope : 0;
            lastWeek.timestamp = pointTimestampIterator;
            pointHistory.push(lastWeek);
        }
        return lastWeek;
    }


    function _fillRecordGaps(LibLockTOS.Point memory week, uint256 timestamp)
        internal
        view
        returns (LibLockTOS.Point memory)
    {
        // Iterate through all past unrecoreded weeks
        uint256 pointTimestampIterator =
            week.timestamp.div(epochUnit).mul(epochUnit);
        while (pointTimestampIterator != timestamp) {
            pointTimestampIterator = Math.min(
                pointTimestampIterator.add(epochUnit),
                timestamp
            );
            int256 deltaSlope = slopeChanges[pointTimestampIterator];
            int256 deltaTime =
                Math.min(pointTimestampIterator.sub(week.timestamp), epochUnit).toInt256();
            week.bias = week.bias.sub(week.slope.mul(deltaTime));
            week.slope = week.slope.add(deltaSlope);
            week.bias = week.bias > 0 ? week.bias : 0;
            week.slope = week.slope > 0 ? week.slope : 0;
            week.timestamp = pointTimestampIterator;
        }
        return week;
    }


    function _updateSlopeChanges(
        LibLockTOS.SlopeChange memory changeNew,
        LibLockTOS.SlopeChange memory changeOld
    ) internal {
        int256 deltaSlopeNew = slopeChanges[changeNew.changeTime];
        int256 deltaSlopeOld = slopeChanges[changeOld.changeTime];
        if (changeOld.changeTime > block.timestamp) {
            deltaSlopeOld = deltaSlopeOld.add(changeOld.slope);
            if (changeOld.changeTime == changeNew.changeTime) {
                deltaSlopeOld = deltaSlopeOld.sub(changeNew.slope);
            }
            slopeChanges[changeOld.changeTime] = deltaSlopeOld;
        }
        if (
            changeNew.changeTime > block.timestamp &&
            changeNew.changeTime > changeOld.changeTime
        ) {
            deltaSlopeNew = deltaSlopeNew.sub(changeNew.slope);
            slopeChanges[changeNew.changeTime] = deltaSlopeNew;
        }
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function currentStakedTotalTOS() external view returns (uint256) {
        return IERC20(tos).balanceOf(address(this));
    }

    function version2() external pure returns (bool) {
        return true;
    }

}