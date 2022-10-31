// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DogCrediting is Ownable, ReentrancyGuard {

    uint256 public payoutRate = 2;
    uint256 public APY = 35;
    uint256 public rewardRatio;

    IERC20 public RewardToken;
    IERC20 public StakedToken;

    bool public isCreditingActive = false;

    uint256 public rewardStartTime;

    // Info of each user.
    struct UserCreditingInfo {
        uint256 amount;
        bool hasCredited;
    }

    struct UserStakedInfo {
        uint256 claimed;
        uint256 staked;
        uint256 reward_time_counter;
        uint256 last_reward_time;
        uint256 last_lp_claim_time;
    }

    mapping(address => UserCreditingInfo) public userCreditInfo;
    mapping(address => UserStakedInfo) public userStakeInfo;

    // EVENTS
    event CreditedLP(address indexed user, uint256 percentage, uint256 amount);
    event EarnRewards(address indexed user, uint256 amount);
    event ClaimedLP(address indexed user, uint256 amount);

    constructor(uint256 _rewardRatio, uint256 _rewardStartTime, IERC20 _rewardToken, IERC20 _stakedToken){
        rewardRatio = _rewardRatio;
        require(_rewardStartTime > block.timestamp, 'must be in future');
        rewardStartTime = _rewardStartTime;
        RewardToken = _rewardToken;
        StakedToken = _stakedToken;
    }

    function creditLPToStaking(uint256 _percentageVested) external nonReentrant {
        require(isCreditingActive, 'not active yet');
        require(_percentageVested <= 100, 'invalid percentage');

        UserCreditingInfo storage user = userCreditInfo[msg.sender];
        require(user.amount > 0, 'nothing to credit');

        uint256 amountToVest = user.amount * _percentageVested / 100;

        userStakeInfo[msg.sender].staked = amountToVest;

        uint256 initialTime = block.timestamp < rewardStartTime ? rewardStartTime : block.timestamp;
        userStakeInfo[msg.sender].last_reward_time = initialTime;
        userStakeInfo[msg.sender].last_lp_claim_time = initialTime;

        uint256 amountRemaining = user.amount - amountToVest;
        if (amountRemaining > 0){
            payoutInstantRewards(msg.sender, amountRemaining);
        }

        user.amount = 0;
        user.hasCredited = true;
        emit CreditedLP(msg.sender, _percentageVested, amountToVest);
    }

    function claimRewards() external nonReentrant {
        require(isCreditingActive, 'not active yet');
        require(block.timestamp > rewardStartTime, 'rewards not active yet');
        UserStakedInfo storage user = userStakeInfo[msg.sender];
        require(user.staked > 0, 'nothing staked');

        payPendingRewards(msg.sender);

    }

    function claimLP() external nonReentrant {
        require(isCreditingActive, 'not active yet');
        require(block.timestamp > rewardStartTime, 'rewards not active yet');
        UserStakedInfo storage user = userStakeInfo[msg.sender];
        require(user.staked > 0, 'nothing staked');

        payPendingRewards(msg.sender);
        payPendingLP(msg.sender);

    }

    function payoutInstantRewards(address user, uint256 _amountStakeToken) internal {
        RewardToken.transfer(user, (_amountStakeToken * rewardRatio * 2) / 1e4);
    }

    function payPendingRewards(address _userAddress) internal {
        UserStakedInfo storage user = userStakeInfo[_userAddress];

        uint256 rewardPayout = pendingRewards(_userAddress);

        uint256 timePassed = block.timestamp - userStakeInfo[_userAddress].last_reward_time;
        user.reward_time_counter += timePassed;
        if (user.reward_time_counter > 50 days){
            user.reward_time_counter = 50 days;
        }

        user.last_reward_time = block.timestamp;

        RewardToken.transfer(msg.sender, rewardPayout);
        emit EarnRewards(_userAddress, rewardPayout);
    }

    function payPendingLP(address _userAddress) internal {
        UserStakedInfo storage user = userStakeInfo[_userAddress];

        uint256 payout = pendingLP(_userAddress);
        user.claimed += payout;
        user.last_lp_claim_time = block.timestamp;

        StakedToken.transfer(msg.sender, payout);
        emit ClaimedLP(_userAddress, payout);
    }

    // VIEW FUNCTIONS
    function pendingRewards(address _user) public view returns(uint256){
        if (block.timestamp < rewardStartTime){
            return 0;
        }

        uint256 stakedRewards = (userStakeInfo[_user].staked - userStakeInfo[_user].claimed) * rewardRatio;
        uint256 rewardsPerYear = stakedRewards * APY / 100;
        uint256 rewardsPerSecond = rewardsPerYear / 365 days;

        uint256 lastTime = userStakeInfo[_user].last_reward_time < rewardStartTime ? rewardStartTime : userStakeInfo[_user].last_reward_time;
        uint256 timePassed = block.timestamp - lastTime;

        if (timePassed + userStakeInfo[_user].reward_time_counter > 50 days){
            timePassed = 50 days - userStakeInfo[_user].reward_time_counter;
        }

        uint256 earnedTotal = (rewardsPerSecond * timePassed) / 1e4;

        return earnedTotal;
    }

    function pendingLP(address _addr) public view returns(uint256 payout) {
        if (block.timestamp < rewardStartTime){
            return 0;
        }

        uint256 share = userStakeInfo[_addr].staked * (payoutRate * 1e18) / (100e18) / (24 hours); //divide the profit by payout rate and seconds in the day
        uint256 lastTime = userStakeInfo[_addr].last_lp_claim_time < rewardStartTime ? rewardStartTime : userStakeInfo[_addr].last_lp_claim_time;
        payout = share * (block.timestamp - lastTime);

        if (userStakeInfo[_addr].claimed + payout > userStakeInfo[_addr].staked) {
            payout = userStakeInfo[_addr].staked - userStakeInfo[_addr].claimed;
        }

        return payout;

    }

    function dogsInLp(address _user) public view returns(uint256){
        return userStakeInfo[_user].staked * rewardRatio;
    }

    // Admin Functions
    function setUserCreditInfo(address[] memory _users, UserCreditingInfo[] memory _usersCreditingData) external onlyOwner {
        require(_users.length == _usersCreditingData.length);
        for (uint256 i = 0; i < _users.length; i++) {
            UserCreditingInfo storage user = userCreditInfo[_users[i]];
            user.amount = _usersCreditingData[i].amount;
        }
    }

    function toggleCreditingActive(bool _isActive) external onlyOwner {
        isCreditingActive = _isActive;
    }

    function updatePayoutRate(uint256 _payoutRate) external onlyOwner {
        payoutRate = _payoutRate;
    }

    function updateRewardStartTime(uint256 _rewardStartTime) external onlyOwner {
        rewardStartTime = _rewardStartTime;
    }

    function updateApy(uint256 _APY) external onlyOwner {
        APY = _APY;
    }

    function updateRewardRatio(uint256 _rewardRatio) external onlyOwner {
        rewardRatio = _rewardRatio;
    }

    function updateRewardToken(IERC20 _rewardToken) external onlyOwner {
        RewardToken = _rewardToken;
    }

    function updateStakedToken(IERC20 _stakedToken) external onlyOwner {
        StakedToken = _stakedToken;
    }

    function unstuckTokens(address _token, uint256 _amount, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}