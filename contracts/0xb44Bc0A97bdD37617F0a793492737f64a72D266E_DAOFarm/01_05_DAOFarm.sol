//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DAOFarm is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint constant HUNDRED_PERCENT = 1e3;
    uint constant ACC_REWARD_MULTIPLIER = 1e36;
    uint constant UPDATE_PERIOD = 60;

    struct User {
        uint shares;
        uint rewardDebt;
        uint requestedUnstakeAt;
    }
    mapping (address => User) public users;

    IERC20 immutable public stakingToken;
    IERC20 immutable public rewardToken;
    address immutable public feeCollector1;
    address immutable public feeCollector2;
    uint immutable public rewardPerPeriod;
    uint immutable public cooldownPeriod;
    uint immutable public cooldownFee;
    uint immutable public cooldownFeeSplit;
    uint immutable public startTime;
    uint immutable public endTime;

    uint public totalShares;
    uint public totalClaimed;
    uint public accRewardPerShare;
    uint public lastUpdateTimestamp;
    
    event Stake(address userAddress, uint amount);
    event RequestUnstake(address userAddress, bool withoutClaim, uint timestamp);
    event Unstake(address userAddress, uint amount, uint fee);
    event Claim(address userAddress, uint reward);
    event Update(uint periodsPassed, uint totalShares, uint totalClaimed, uint accRewardPerShare, uint timestamp);

    modifier withUpdate() {
        update();
        _;
    }

    constructor(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        address _feeCollector1,
        address _feeCollector2,
        uint _rewardPerPeriod,
        uint _cooldownPeriod,
        uint _cooldownFee,
        uint _cooldownFeeSplit,
        uint _startTime,
        uint _endTime
    ) {
        require(address(_stakingToken) != address(0));
        require(address(_rewardToken) != address(0));
        require(_feeCollector1 != address(0));
        require(_feeCollector2 != address(0));
        require(_cooldownFee <= HUNDRED_PERCENT);
        require(_cooldownFeeSplit <= HUNDRED_PERCENT);
        require(_startTime > block.timestamp);
        require(_startTime < _endTime);

        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        feeCollector1 = _feeCollector1;
        feeCollector2 = _feeCollector2;
        rewardPerPeriod = _rewardPerPeriod;
        cooldownPeriod = _cooldownPeriod;
        cooldownFee = _cooldownFee;
        cooldownFeeSplit = _cooldownFeeSplit;
        startTime = _startTime;
        endTime = _endTime;
        lastUpdateTimestamp = _startTime;
    }
    
    // =================== EXTERNAL FUNCTIONS  =================== //

    /**
        Check whether some update periods have passed and if so, increase the pending reward of all users.
     */
    function update() public {
        uint currentTimestamp = block.timestamp;
        if (currentTimestamp > endTime) {
            currentTimestamp = endTime;
        }
        require(currentTimestamp > startTime, "before startTime");

        uint periodsPassed = (currentTimestamp - lastUpdateTimestamp) / UPDATE_PERIOD;
        if (periodsPassed > 0 && totalShares > 0) {
            uint reward = rewardPerPeriod * periodsPassed;
            accRewardPerShare += ACC_REWARD_MULTIPLIER * reward / totalShares;
            lastUpdateTimestamp += periodsPassed * UPDATE_PERIOD;
        }

        emit Update(periodsPassed, totalShares, totalClaimed, accRewardPerShare, block.timestamp);
    }

    /**
        Stake tokens.
        @param amount amount to stake
     */
    function stake(uint amount) external nonReentrant withUpdate {
        User storage user = users[msg.sender];
        require(amount > 0, "0 amount");
        require(user.requestedUnstakeAt == 0, "unstake requested");

        uint balanceBefore = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint receivedAmount = stakingToken.balanceOf(address(this)) - balanceBefore;

        user.shares += receivedAmount;
        user.rewardDebt += _calculateAbsoluteReward(receivedAmount);
        totalShares += receivedAmount;

        emit Stake(msg.sender, receivedAmount);
    }

    /**
        Enter the cooldown period for unstaking without any fee after the period passes.
        Users can't stake or claim while in the cooldown period.
        @param withoutClaim in case the pending rewards can't be claimed, there's still this option to request unstake without claiming
     */
    function requestUnstake(bool withoutClaim) external nonReentrant withUpdate {
        User storage user = users[msg.sender];
        require(user.requestedUnstakeAt == 0, "unstake requested already");
        _requestUnstake(withoutClaim);
    }

    /**
        Unstaking before the cooldown period ends causes a fee on the staked amount (it's free of charge if the farm staking has ended).
     */
    function unstake() external nonReentrant withUpdate {
        User storage user = users[msg.sender];

        if (user.requestedUnstakeAt == 0) {
            _requestUnstake(false);
        }

        uint unstakeAmount = user.shares;
        bool earlyUnstake = block.timestamp < user.requestedUnstakeAt + cooldownPeriod;
        uint fee;
        if (earlyUnstake) {
            fee = _applyPercentage(unstakeAmount, cooldownFee);
            uint feeSplit1 = _applyPercentage(fee, cooldownFeeSplit);
            uint feeSplit2 = fee - feeSplit1;
            stakingToken.safeTransfer(feeCollector1, feeSplit1);
            stakingToken.safeTransfer(feeCollector2, feeSplit2);
        }
        unstakeAmount -= fee;
    
        stakingToken.safeTransfer(msg.sender, unstakeAmount);
        delete users[msg.sender];

        emit Unstake(msg.sender, unstakeAmount, fee);
    }

    /**
        Claim all the pending rewards. 
    */
    function claim() external nonReentrant withUpdate returns (uint claimableReward) {
        claimableReward = getClaimableReward(msg.sender); 
        require(claimableReward > 0, "nothing to claim");
        _claim(msg.sender);
    }

    // =================== INTERNAL FUNCTIONS  =================== //

    function _claim(address userAddress) internal {
        User storage user = users[userAddress];

        uint claimableReward = getClaimableReward(userAddress);
        if (claimableReward > 0) {
            require(getRewardBalance() >= claimableReward, "not enough reward balance");
            user.rewardDebt += claimableReward;
            totalClaimed += claimableReward;
            rewardToken.safeTransfer(userAddress, claimableReward);
            emit Claim(userAddress, claimableReward);
        }
    }

    function _requestUnstake(bool withoutClaim) internal {
        User storage user = users[msg.sender];
        require(user.shares > 0, "nothing to unstake");

        if (!withoutClaim) {
            _claim(msg.sender);
        }

        user.requestedUnstakeAt = block.timestamp;
        totalShares -= user.shares;
        emit RequestUnstake(msg.sender, withoutClaim, block.timestamp);
    }

    // =================== VIEW FUNCTIONS  =================== //

    function getClaimableReward(address userAddress) public view returns (uint reward) {
        User storage user = users[userAddress];
        if (user.requestedUnstakeAt > 0) {
            return 0;
        }

        uint absoluteReward = _calculateAbsoluteReward(user.shares);
        reward = absoluteReward - user.rewardDebt;
    }

    function getRewardBalance() public view returns (uint rewardBalance) {
        uint balance = rewardToken.balanceOf(address(this));

        if (rewardToken != stakingToken) {
            return balance;
        } else {
            return balance - totalShares;
        }
    }

    function getFarmInfo(address userAddress) public view returns (IERC20, IERC20, uint, uint, uint, uint, uint, uint, uint, uint) {
        User storage user = users[userAddress];
        return (
            stakingToken,
            rewardToken,
            rewardPerPeriod,
            cooldownPeriod,
            cooldownFee,
            startTime,
            endTime,
            totalShares,
            user.shares,
            user.requestedUnstakeAt
        );
    }

    function _calculateAbsoluteReward(uint shares) private view returns (uint absoluteReward) {
        return accRewardPerShare * shares / ACC_REWARD_MULTIPLIER;
    }

    function _applyPercentage(uint value, uint percentage) internal pure returns (uint) {
        return value * percentage / HUNDRED_PERCENT;
    }
}