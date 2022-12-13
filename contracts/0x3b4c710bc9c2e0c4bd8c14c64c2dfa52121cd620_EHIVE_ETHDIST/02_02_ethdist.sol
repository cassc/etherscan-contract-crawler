// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./contract.sol";

contract EHIVE_ETHDIST is Ownable {
    using SafeMath for uint256;

    EHIVE public eHive;
    bool public stakingEnabled = false;
    uint256 public totalStaked;
    uint256 public totalClaimed;
    uint256[] public monthlyReward; // [timestamp, totalStaked, weekly eth]

    struct Staker {
        address staker;
        uint256 start;
        uint256 staked;
        uint256 earned;
        uint256 ethEarned;
    }

    struct ClaimHistory {
        uint256[] dates;
        uint256[] amounts;
    }

    // stake data
    mapping(address => Staker) public stakers;
    mapping(address => ClaimHistory) private _claimHistory;
    mapping(address => mapping(uint256 => bool)) public userMonthlyClaimed; //specific to the months timestmap

    event Stake(uint256 amount);
    event Claim(uint256 amount);

    constructor (EHIVE native) {
        eHive = native;
    }

    modifier isStakingEnabled() {
        require(stakingEnabled, "Staking is not enabled.");
        _;
    }

    /**
    * @dev Checks if holder is staking
    */
    function isStaking(address stakerAddr) public view returns (bool) {
        return stakers[stakerAddr].staker == stakerAddr;
    }

    /**
    * @dev Returns how much staker is staking
    */
    function userStaked(address staker) public view returns (uint256) {
        return stakers[staker].staked;
    }

    /**
    * @dev Returns how much staker has claimed over time
    */
    function userClaimHistory(address staker) public view returns (ClaimHistory memory) {
        return _claimHistory[staker];
    }

    /**
    * @dev Returns how much staker has earned
    */
    function userEarned(address staker) public view returns (uint256) {
        uint256 currentlyEarned = _userEarned(staker);
        uint256 previouslyEarned = stakers[msg.sender].earned;

        if (previouslyEarned > 0) return currentlyEarned.add(previouslyEarned);
        return currentlyEarned;
    }

    function _userEarned(address staker) private view returns (uint256) {
        require(isStaking(staker), "User is not staking.");

        uint256 staked = userStaked(staker);
        uint256 stakersStartInSeconds = stakers[staker].start.div(1 seconds);
        uint256 blockTimestampInSeconds = block.timestamp.div(1 seconds);
        uint256 secondsStaked = blockTimestampInSeconds.sub(stakersStartInSeconds);

        uint256 earn = staked.mul(eHive.apr()).div(100);
        uint256 rewardPerSec = earn.div(365).div(24).div(60).div(60);
        uint256 earned = rewardPerSec.mul(secondsStaked);

        return earned;
    }
 
    /**
    * @dev Stake tokens in validator
    */
    function stake(uint256 stakeAmount) external isStakingEnabled {
        require(eHive.totalSupply() <= eHive.maxSupply(), "There are no more rewards left to be claimed.");

        // Check user is registered as staker
        if (isStaking(msg.sender)) {
            stakers[msg.sender].earned += _userEarned(msg.sender);
            stakers[msg.sender].staked += stakeAmount;
            stakers[msg.sender].start = block.timestamp;
        } else {
            stakers[msg.sender] = Staker(msg.sender, block.timestamp, stakeAmount, 0, 0);
        }

        totalStaked += stakeAmount;
        eHive.transferFrom(msg.sender, address(this), stakeAmount);
        eHive.stake(stakeAmount, 0);

        emit Stake(stakeAmount);
    }
    
    /**
    * @dev Claim earned tokens from stake in validator
    */
    function claim() external isStakingEnabled {
        require(isStaking(msg.sender), "You are not staking!?");
        require(eHive.totalSupply() <= eHive.maxSupply(), "There are no more rewards left to be claimed.");

        uint256 reward = userEarned(msg.sender);

        _claimHistory[msg.sender].dates.push(block.timestamp);
        _claimHistory[msg.sender].amounts.push(reward);
        totalClaimed += reward;

        if (eHive.balanceOf(address(this)) < reward) eHive.claim(0);
        eHive.transfer(msg.sender, reward);

        stakers[msg.sender].start = block.timestamp;
        stakers[msg.sender].earned = 0;
    }

    /**
    * @dev Claim earned and staked tokens from validator
    */
    function unstake() external {
        require(isStaking(msg.sender), "You are not staking!?");

        uint256 toStake = eHive.userStaked(address(this), 0);
        uint256 reward = userEarned(msg.sender);
        uint256 staked = stakers[msg.sender].staked;
        uint256 unstakeAmt = staked.add(reward);
        if (eHive.balanceOf(address(this)) < unstakeAmt) eHive.unstake(0);

        if (eHive.totalSupply().add(reward) < eHive.maxSupply() && stakingEnabled) {
            _claimHistory[msg.sender].dates.push(block.timestamp);
            _claimHistory[msg.sender].amounts.push(reward);
            totalClaimed += reward;

            eHive.transfer(msg.sender, unstakeAmt);
        } else {
            eHive.transfer(msg.sender, staked);
        }

        totalStaked -= staked;

        delete stakers[msg.sender];

        eHive.stake(toStake.sub(staked), 0);
    }

    /**
    * @dev Add monthly eth reward for stakers
    */
    function addRewards() external payable onlyOwner {
        monthlyReward = [block.timestamp, totalStaked, msg.value];
    }

    /**
    * @dev Claiming of eth rewards
    */
    function claimETHRewards() external {
        require(!userMonthlyClaimed[msg.sender][monthlyReward[0]], "You already claimed your monthly reward.");
        require(stakers[msg.sender].start < monthlyReward[0]);

        uint256 staked = stakers[msg.sender].staked;
        uint256 total = monthlyReward[1];
        uint256 P = (staked * 1e18) / total;
        uint256 reward = monthlyReward[2] * P / 1e18;

        userMonthlyClaimed[msg.sender][monthlyReward[0]] = true;

        stakers[msg.sender].ethEarned += reward;
        payable(msg.sender).transfer(reward);

        emit Claim(reward);
    }

    /**
    * @dev Enables/disables staking
    */
    function setStakingState(bool onoff) external onlyOwner {
        stakingEnabled = onoff;
    }
}