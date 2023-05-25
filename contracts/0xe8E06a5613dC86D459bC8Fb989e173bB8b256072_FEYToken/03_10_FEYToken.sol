// SPDX-License-Identifier: -- 💰 --

import './Token.sol';

pragma solidity ^0.7.3;

contract FEYToken is Token {

    using SafeMath for uint256;

    /**
        * @notice returns the interest rate by getting the global variable
        * YEARLY_INTEREST and subtracting the percentage passed.
        * Lowers the default interest rate as amount staked rises towards the totalSupply.
        * Used to record the rates for snapshots + to calculate stake interest
        * @param _percentage any uint256 figure
        * @return interestRate
     */
    function getInterestRateYearly(
        uint256 _percentage
    )
        public
        pure
        returns (uint256 interestRate)
    {
        return _percentage > 100
            ? uint256(YEARLY_INTEREST).mul(uint256(10000)).div(_percentage)
            : YEARLY_INTEREST.mul(100);
    }
    
    /**
        * @notice a no args function used to get current APY
        * @dev _precision in getPercent is fixed to 4
        * @return percentage -- totalStaked on a particular day out of totalSupply
        * @return interestRateYearly -- APY based on relative size of current total stakes
     */
    function getYearlyInterestLatest()
        public
        view
        returns (
            uint256 percentage,
            uint256 interestRateYearly
        )
    {
        percentage = getPercent(
            globals.totalStakedAmount,
            totalSupply,
            4
        );

        interestRateYearly = getInterestRateYearly(
            percentage
        );
    }

    /**
        * @notice function used to get APY of a specific day
        * @param _day integer for the target day, starting @ 0
        * @dev _precision in getPercent is fixed to 4
        * @return percentage -- totalStaked on a particular day out of totalSupply
        * @return interestRateYearly -- APY based on relative size of stake
     */
    function getYearlyInterestHistorical(
        uint256 _day
    )
        public
        view
        returns (
            uint256 percentage,
            uint256 interestRateYearly
        )
    {
        SnapShot memory s = snapshots[_day];

        if (s.totalSupply == 0) {
            return getYearlyInterestLatest();
        }

        percentage = getPercent(
            s.totalStakedAmount,
            s.totalSupply,
            4
        );

        interestRateYearly = getInterestRateYearly(
            percentage
        );
    }

    /**
        * @notice calculates amount of interest earned per second
        * @param _stakedAmount principal amount
        * @param _totalStakedAmount summation of principal amount staked by everyone
        * @param _seconds time spent earning interest on a particular day
        * _seconds will be passed as the full SECONDS_IN_DAY for full days that we staked
        * _seconds will be the seconds that have passed by the time getInterest is called on the last day
        * @dev _precision in getPercent is fixed to 4
        * @return durationInterestAmt -- totalStaked on a particular day out of totalSupply
     */
    function getInterest(
        uint256 _stakedAmount,
        uint256 _totalStakedAmount,
        uint256 _seconds
    )
        public
        view
        returns (uint256 durationInterestAmt)
    {
        uint256 percentage = getPercent(
            _totalStakedAmount,
            totalSupply,
            4
        );

        uint256 interestRateYearly = getInterestRateYearly(
            percentage
        );

        uint256 yearFullAmount = _stakedAmount
            .mul(interestRateYearly)
            .div(100);

        uint256 dailyInterestAmt = getPercent(
            yearFullAmount,
            31556952,
            0
        );

        durationInterestAmt = dailyInterestAmt
            .mul(_seconds)
            .div(100);
    }

    /**
         * @notice admin function to close a matured stake OBO the staker
         * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
         * @dev can only close after all of the seconds of the last day have passed
      */
    function closeGhostStake(
        uint256 _stakingId
    )
        external
        onlyOwner
    {
        (uint256 daysOld, uint256 secondsOld) =

        getStakeAge(
            _stakingId
        );

        require(
            daysOld == MAX_STAKE_DAYS &&
            secondsOld == SECONDS_IN_DAY,
            'FEYToken: not old enough'
        );

        _closeStake(
            stakeList[_stakingId].userAddress,
            _stakingId
        );

        emit ClosedGhostStake(
            daysOld,
            secondsOld,
            _stakingId
        );
    }

    /**
        * @notice calculates number of days and remaining seconds on current day that a stake is open
        * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
        * @return daysTotal -- number of complete days that the stake has been open
        * @return secondsToday -- number of seconds the stake has been open on the current day
     */
    function getStakeAge(
        uint256 _stakingId
    )
        public
        view
        returns (
            uint256 daysTotal,
            uint256 secondsToday
        )
    {
        StakeElement memory _stakeElement = stakeList[_stakingId];

        uint256 secondsTotal = getNow()
            .sub(_stakeElement.stakedAt);

        daysTotal = secondsTotal
            .div(SECONDS_IN_DAY);

        if (daysTotal > MAX_STAKE_DAYS) {

            daysTotal = MAX_STAKE_DAYS;
            secondsToday = SECONDS_IN_DAY;

        } else {
            secondsToday = secondsTotal
                .mod(SECONDS_IN_DAY);
        }
    }

    /**
        * @notice calculates amount of interest due to be credited to the staker based on:
        * number of days and remaining seconds on current day that a stake is open
        * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
        * @return stakeInterest -- total interest per second the stake was open on each day
     */
    function getStakeInterest(
        uint256 _stakingId
    )
        public
        view
        returns (
            uint256 stakeInterest
        )
    {
        StakeElement memory _stakeElement = stakeList[_stakingId];

        if (_stakeElement.isActive == false) {

            stakeInterest = _stakeElement.interestAmount;

        } else {

            (
                uint256 daysTotal,
                uint256 secondsToday
            ) = getStakeAge(_stakingId);

            uint256 finalDay = _currentFeyDay();
            uint256 startDay = finalDay.sub(daysTotal);

            for (uint256 _day = startDay; _day < finalDay; _day++) {
                stakeInterest += getInterest(
                    _stakeElement.stakedAmount,
                    snapshots[_day].totalStakedAmount,
                    SECONDS_IN_DAY
                );
            }

            stakeInterest += getInterest(
                _stakeElement.stakedAmount,
                globals.totalStakedAmount,
                secondsToday
            );
        }
    }

    /**
        * @notice penalties are taken if you close a stake before the completion of the 4th day
        * if closed before the end of the 15th day: 7.5% of staked amount is penalized
        * if closed before the end of the 30th day: 5% of staked amount is penalized
        * if closed before the end of the 45th day: 2.5% of staked amount is penalized
        * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
        * @return penaltyAmount -- amount that will be debited from the stakers principal when they close their stake
     */
    function getStakePenalty(
        uint256 _stakingId
    )
        public
        view
        returns (uint256 penaltyAmount)
    {
        StakeElement memory _stakeElement = stakeList[_stakingId];

        uint256 daysDifference = getNow()
            .sub(_stakeElement.stakedAt)
            .div(SECONDS_IN_DAY);

        if (daysDifference < 15) {

            penaltyAmount = percentCalculator(
                _stakeElement.stakedAmount,
                750
            );

        } else if (daysDifference < 30) {

            penaltyAmount = percentCalculator(
                _stakeElement.stakedAmount,
                500
            );

        } else if (daysDifference < 45) {

            penaltyAmount = percentCalculator(
                _stakeElement.stakedAmount,
                250
            );
        }
    }

    /**
        * @notice calculates principal + interest - penalty (if applicable)
        * Note: this does not calculate a return rate, only what the sum would be if the stake was closed at that moment
        * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
        * @dev the calculated value is only in memory
        * @return uint256 -- principal + interest - penalty
     */
    function estimateReturn(
        uint256 _stakingId
    )
        public
        view
        returns (uint256)
    {
        StakeElement memory _stakeElement = stakeList[_stakingId];

        if (_stakeElement.isActive == false) {
            return  _stakeElement.returnAmount;
        }

        return _stakeElement.stakedAmount
            .add(getStakeInterest(_stakingId))
            .sub(getStakePenalty(_stakingId));
    }

    /**
        * @notice close a stake older than 1 full day to:
        * 1) credit principal + interest - penalty to the balance of the staker
        * 2) update totalStakedAmount in globals
        * 3) take snapshot of current FEY status before the stake closes
        * No interest is accrued unless the stake is at least on its 4th day
        * Updates global variables to reflect the closed stake
        * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
        * @return stakedAmount -- represents the total calculated by: principal + interest - penalty
        * @return penaltyAmount -- amount that will be debited from the stakers principal when they close their stake
        * @return interestAmount -- amount that will be debited from the stakers principal when they close their stake
     */
    function closeStake(
        uint256 _stakingId
    )
        public
        snapshotTriggerOnClose
        returns (
            uint256 stakedAmount,
            uint256 penaltyAmount,
            uint256 interestAmount
        )
    {
        return _closeStake(
            msg.sender,
            _stakingId
        );
    }

    function _closeStake(
        address _staker,
        uint256 _stakingId
    )
        internal
        returns (
            uint256 stakedAmount,
            uint256 penaltyAmount,
            uint256 interestAmount
        )
    {
        StakeElement memory _stakeElement = stakeList[_stakingId];

        uint256 daysDifference = getNow()
            .sub(_stakeElement.stakedAt)
            .div(SECONDS_IN_DAY);

        require(
            daysDifference >= 3,
            'FEYToken: immature stake'
        );

        require(
            _stakeElement.userAddress == _staker,
            'FEYToken: wrong stake owner'
        );

        require(
            _stakeElement.isActive,
            'FEYToken: stake not active'
        );

        _stakeElement.isActive = false;

        stakedAmount = _stakeElement.stakedAmount;

        if (daysDifference >= 45) {
            interestAmount = getStakeInterest(
                _stakingId
            );
        }

        penaltyAmount = getStakePenalty(
            _stakingId
        );

        totalSupply = totalSupply
            .add(interestAmount)
            .sub(penaltyAmount);

        _stakeElement.interestAmount = interestAmount;
        _stakeElement.returnAmount = stakedAmount
            .add(interestAmount)
            .sub(penaltyAmount);

        stakeList[_stakingId] = _stakeElement;

        balances[_staker] =
        balances[_staker].add(_stakeElement.returnAmount);

        globals.totalStakedAmount =
        globals.totalStakedAmount.sub(stakedAmount);

        emit StakeEnd(
            _stakingId,
            _staker,
            _stakeElement.returnAmount
        );

        emit Transfer(
            address(0x0),
            _staker,
            _stakeElement.returnAmount
        );
    }

    /**
        * @notice open a stake:
        * 1) must be greater than MINIMUM_STAKE in Declarations
        * 2) address opening the stake must have the amount of funds that they wish to stake in their balances[0xaddress]
        * 3) increment the global incrementId that is used to set the stakingId
        * 3) take snapshot of current FEY status before the stake is opened
        * Updates global variables to reflect the new stake
        * @param _amount the amount that you want to stake, will become your principal amount
        * @return true if no revert or error occurs
     */
    function openStake(
        uint256 _amount
    )
        external
        incrementId
        snapshotTriggerOnOpen
        returns (bool)
    {
        require(
            _transferCheck(
                msg.sender,
                address(0x0),
                _amount,
                true
            ),
            'FEYToken: _transferCheck failed'
        );

        require(
            _amount >= MINIMUM_STAKE,
            'FEYToken: stake below minimum'
        );

        balances[msg.sender] =
        balances[msg.sender].sub(_amount);

        stakeList[globals.stakingId] = StakeElement(
            msg.sender,
            _amount,
            0,
            0,
            getNow(),
            true
        );

        globals.totalStakedAmount =
        globals.totalStakedAmount.add(_amount);

        emit StakeStart(
            globals.stakingId,
            msg.sender,
            _amount
        );

        emit Transfer(
            msg.sender,
            address(0),
            _amount
        );

        return true;
    }

    /**
        * @notice getter for the data of a specific stake
        * @param _stakingId ID of the stake, used as the Key from the stakeList mapping
        * @return _stakedAmount -- represents the total calculated by: principal + interest - penalty
        * @return _userAddress -- address that was used to open the stake
        * @return _returnAmount -- principal + interest - penalty
        * @return interestAmount -- amount of interest accrued after closing the stake
        * @return _stakedAt -- timestamp of when stake was opened
        * @return _isActive -- boolean for if the stake is open and accruing interest
     */
    function getStaking(
        uint256 _stakingId
    )
        external
        view
        returns (
            uint256 _stakedAmount,
            address _userAddress,
            uint256 _returnAmount,
            uint256 interestAmount,
            uint256 _stakedAt,
            bool _isActive
        )
    {
        StakeElement memory _stakeElement = stakeList[_stakingId];

        return (
            _stakeElement.stakedAmount,
            _stakeElement.userAddress,
            _stakeElement.returnAmount,
            _stakeElement.interestAmount,
            _stakeElement.stakedAt,
            _stakeElement.isActive
        );
    }
}