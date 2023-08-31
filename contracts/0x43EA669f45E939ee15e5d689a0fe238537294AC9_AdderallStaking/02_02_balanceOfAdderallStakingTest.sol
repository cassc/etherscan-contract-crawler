// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdderallTokenTest.sol";

contract AdderallStaking {
    AdderallToken public adderallToken;

    address public owner;
    uint256 public k = 1000; // represents 1/10th or 10%
    uint256 constant DAY_IN_SECONDS = 86400; // 24 hours * 60 minutes * 60 seconds
    uint256 public totalStaked;
    uint256 public lockupPeriod = 0 seconds;
    uint256 public rewardPerTokenStored = 0; 
    uint256 public lastUpdateTime;


    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastUpdated;
        uint256 reward;
        uint256 lastTotalRewardsPoolAtUpdate;
        uint256 lockupEndTime;
    }

    mapping(address => StakerInfo) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event DecayFactorUpdated(uint256 newK);
    event LockupPeriodUpdated(uint256 newLockupPeriod);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address payable _adderallToken) {
        adderallToken = AdderallToken(_adderallToken);
        owner = msg.sender;
    }

    function setDecayFactor(uint256 newK) external onlyOwner {
        require(newK <= 10000, "Decay factor should be between 0 and 10000");
        k = newK;
        emit DecayFactorUpdated(newK);
    }

    function setLockupPeriod(uint256 _newLockupPeriod) external onlyOwner {
        lockupPeriod = _newLockupPeriod;
        emit LockupPeriodUpdated(_newLockupPeriod);
    }

    function getCurrentRewardRate() public view returns (uint256) {
        return (adderallToken.balanceOf(address(this)) * k) / (10000 * DAY_IN_SECONDS);
    }

    function totalRewardBalance() external view returns (uint256) {
        return adderallToken.balanceOf(address(this)) - totalStaked;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) *
                getCurrentRewardRate() *
                1e18) / totalStaked);
    }

    function stakeTokens(uint256 _amount) public {
        StakerInfo storage staker = stakers[msg.sender];

        require(
            adderallToken.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        updateReward(msg.sender);

        staker.stakedAmount += _amount;
        staker.lockupEndTime = block.timestamp + lockupPeriod;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    function unstakeTokens(uint256 _amount) public {
        StakerInfo storage staker = stakers[msg.sender];

        updateReward(msg.sender);

        require(
            block.timestamp >= staker.lockupEndTime,
            "Tokens are still locked up"
        );
        require(
            staker.stakedAmount >= _amount,
            "Amount greater than staked balance"
        );

        staker.stakedAmount -= _amount;
        totalStaked -= _amount;

        require(adderallToken.transfer(msg.sender, _amount), "Transfer failed");
        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() public {
        updateReward(msg.sender);

        uint256 reward = stakers[msg.sender].reward;
        require(
            adderallToken.balanceOf(address(this)) >= reward,
            "Not enough tokens in the contract to claim"
        );

        stakers[msg.sender].reward = 0;

        require(adderallToken.transfer(msg.sender, reward), "Transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    function updateReward(address _user) internal {
        uint256 currentRewardPerToken = rewardPerToken();
        StakerInfo storage staker = stakers[_user];

        staker.reward +=
            (staker.stakedAmount *
                (currentRewardPerToken - staker.lastTotalRewardsPoolAtUpdate)) /
            1e18;
        staker.lastTotalRewardsPoolAtUpdate = currentRewardPerToken;
        staker.lastUpdated = block.timestamp;

        rewardPerTokenStored = currentRewardPerToken; 
        lastUpdateTime = block.timestamp;
    }

    fallback() external {
        revert("ETH not accepted");
    }
}
