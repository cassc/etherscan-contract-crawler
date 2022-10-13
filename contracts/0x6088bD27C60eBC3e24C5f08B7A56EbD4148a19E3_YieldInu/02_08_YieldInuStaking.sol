//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract YieldInuStaking {
    using SafeMath for uint256;

    uint256 private constant ONE_YEAR = 365 days;
    uint256 private constant ONE_WEEK = 7 days;
    uint16 private constant PERCENT_DENOMENATOR = 10000;

    uint256 public fullyVestedPeriod = 30 days;
    uint256 public withdrawsPerPeriod = 10;
    uint256 public usersStaked;
    uint256 public totalStaked;
    uint256 public totalVested;

    struct stakePlans {
        uint256 apy;
        uint256 lockDuration;
    }

    stakePlans[] _planOptions;

    struct StakeInfo {
        uint256 amount;
        uint256 apy;
        uint256 since;
        uint256 duration;
    }

    struct VestInfo {
        uint256 start;
        uint256 end;
        uint256 totalWithdraws;
        uint256 withdrawsCompleted;
        uint256 amount;
    }

    mapping(address => StakeInfo) public stakers;
    mapping(address => VestInfo) public vesting;
    mapping(address => uint256) public claimedRewards;
    mapping(address => uint256) public activeYield;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public yieldToWithdraw;
    mapping(address => bool) public hasStake;
    mapping(address => bool) public hasVest;
    mapping(address => uint256) public tokensForUnstake;

    function _createPlans() internal{
        _planOptions.push(stakePlans({apy: 1500, lockDuration: 0}));
        _planOptions.push(stakePlans({apy: 4000, lockDuration: 14}));
        _planOptions.push(stakePlans({apy: 8000, lockDuration: 30}));
        _planOptions.push(stakePlans({apy: 15000, lockDuration: 120}));
        _planOptions.push(stakePlans({apy: 45000, lockDuration: 360}));
    }

    function addPlan(uint256 _apy, uint256 _lockDuration) internal {
        _planOptions.push(stakePlans({apy: _apy, lockDuration: _lockDuration}));
    }

    function removePlan(uint256 _index) internal {
        _planOptions[_index] = _planOptions[_planOptions.length - 1];
        _planOptions.pop();
    }

    function updatePlan(uint256 _plan, uint256 _apy, uint256 _lockDuration) internal{
        _planOptions[_plan].apy = _apy;
        _planOptions[_plan].lockDuration = _lockDuration;
    }

    function updateStake(address _user, uint256 _amount, uint256 _duration, uint256 _apy) internal{
        stakers[_user].amount = _amount;
        stakers[_user].duration = _duration;
        stakers[_user].apy = _apy;
    }   

    function _stake(
        address _user,
        uint256 _amount,
        uint256 _plan
    ) internal {
        require(!hasStake[_user], "One active stake per account");
        require(_amount > 0, "Cannot stake nothing");

        stakers[_user] = StakeInfo({
            amount: _amount,
            apy: _planOptions[_plan].apy,
            since: block.timestamp,
            duration: _planOptions[_plan].lockDuration
        });

        hasStake[_user] = true;
        usersStaked += 1;
        totalStaked += _amount;
    }

    function _claimAndVestRewards(address _user) public {
        require(block.timestamp > lastClaim[_user] + ONE_WEEK);
        lastClaim[_user] = block.timestamp;
        uint256 totalEarnedAmount = _calculateReward(_user);
        require(totalEarnedAmount > claimedRewards[_user]);
        uint256 amountToVest = totalEarnedAmount - claimedRewards[_user];

        if(hasStake[_user]) {
            amountToVest = amountToVest += activeYield[_user];
        }

        vesting[_user] = VestInfo({
            start: block.timestamp,
            end: block.timestamp + fullyVestedPeriod,
            totalWithdraws: withdrawsPerPeriod,
            withdrawsCompleted: 0,
            amount: amountToVest
        });

        hasVest[_user] = true;
        activeYield[_user] = amountToVest;
        claimedRewards[_user] = totalEarnedAmount;
    }

    function _calculateVested(address _user) public {
        VestInfo memory _userVest = vesting[_user];
        require(_userVest.amount > 0, "Must have vest pending");
        require(_userVest.withdrawsCompleted < _userVest.totalWithdraws, "All withdrawals completed");

        uint256 _tokensPerWithdrawPeriod = _userVest.amount / _userVest.totalWithdraws;
        uint256 _withdrawsAllowed = checkWithdrawAllowed(_user);

        _withdrawsAllowed = _withdrawsAllowed > _userVest.totalWithdraws
        ? _userVest.totalWithdraws
        : _withdrawsAllowed;

        require(_userVest.withdrawsCompleted < _withdrawsAllowed);

        uint256 _withdrawsToComplete = _withdrawsAllowed - _userVest.withdrawsCompleted;
        _userVest.withdrawsCompleted = _withdrawsAllowed;

        yieldToWithdraw[_user] = (_tokensPerWithdrawPeriod * _withdrawsToComplete);

        vesting[_user].amount = vesting[_user].amount - yieldToWithdraw[_user];

        if(_userVest.withdrawsCompleted == _userVest.totalWithdraws) {
            delete vesting[_user];
            hasVest[_user] = false;
        }
    }

    function checkWithdrawAllowed(address _user) public view returns(uint256) {
        VestInfo memory _vest = vesting[_user];
        uint256 timePerWithdrawPeriod = (_vest.end - _vest.start) / _vest.totalWithdraws;
        return (block.timestamp - _vest.start) / timePerWithdrawPeriod;
    }

    
    function _calculateReward(address _user) public view returns(uint256) {
        StakeInfo memory _userStake = stakers[_user];
        uint256 stakeDuration = block.timestamp - _userStake.since;
        return (_userStake.amount * _userStake.apy * stakeDuration) / PERCENT_DENOMENATOR / ONE_YEAR;
    }

    function _unstake (
        address _user
    ) public {
        StakeInfo memory _stakes = stakers[_user];
        bool _isUnstakingEarly = block.timestamp < _stakes.since + _stakes.duration;
        if(_isUnstakingEarly) {
            uint256 _timeStaked = block.timestamp - _stakes.since;
            uint256 _earnedAmount = (_stakes.amount * _timeStaked) / _stakes.duration;
            tokensForUnstake[_user] = _earnedAmount;
        }else {
            tokensForUnstake[_user] = _stakes.amount;
        }

        uint256 _totalEarnedAmount  = _calculateReward(_user);
        if(_totalEarnedAmount > claimedRewards[_user]) {
            _claimAndVestRewards(_user);
        }

        delete stakers[_user];
        hasStake[_user] = false;
        usersStaked -= 1;
        totalStaked -= _stakes.amount;

    }

}