pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//Reward per second is 0 on deploy. once it has been set, staking has started. no takebacks.
contract PepeYespStaking is Ownable, ReentrancyGuard {
    bool public stakingPaused = true;
    uint256 public stakingPeriod = 1209600; //14 days
    uint256 public rewardPoolSize = 3000000 * 10**18; // 3mil
    uint256 public rewardPerSecond = rewardPoolSize / stakingPeriod;
    IERC20 public stakingToken = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933); // PEPE
    IERC20 public rewardToken = IERC20(0x46ccA329970B33e1a007DD4ef0594A1cedb3E72a); // YESP

    event Stake(address indexed stakoor, uint256 amount);
    event Withdraw(address indexed stakoor, uint256 amount);
    event Harvest(address indexed stakoor, uint256 rewards);

    uint256 public totalStaked = 0;
    mapping(address => uint256) public stakingTimestamps;
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public rewardsHarvested;

    uint256 public taxFee = 500;
    uint256 public taxesHeld = 0;

    function stake(uint256 amount) external nonReentrant {
        require(!stakingPaused, "Staking paused");
        require(stakingToken.allowance(msg.sender, address(this)) >= amount, "PEPE Allowance");
        require(stakingToken.balanceOf(msg.sender) >= amount, "PEPE Balance");
        if (stakedAmount[msg.sender] != 0 ) { _harvest(); }

        uint256 taxedAmount = taxFee * amount / 10000;

        stakingTimestamps[msg.sender] = block.timestamp;
        stakedAmount[msg.sender] += (amount - taxedAmount);
        totalStaked += (amount - taxedAmount);
        taxesHeld += taxedAmount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender, amount);
    }

    function withdraw() external nonReentrant {
        require((stakedAmount[msg.sender] > 0), "Nothing staked");
        _harvest();
        totalStaked -= stakedAmount[msg.sender];
        stakingToken.transfer(msg.sender, stakedAmount[msg.sender]);
        emit Withdraw(msg.sender, stakedAmount[msg.sender]);
        stakedAmount[msg.sender] = 0;
    }

    function _harvest() private {
        uint256 timeStaked = block.timestamp - stakingTimestamps[msg.sender];
        uint256 rewardAmount = timeStaked * rewardPerSecond * stakedAmount[msg.sender] / totalStaked;
        require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Rewards insufficient");
        stakingTimestamps[msg.sender] = block.timestamp;
        rewardsHarvested[msg.sender] += rewardAmount;
        rewardToken.transfer(msg.sender, rewardAmount);
        emit Harvest(msg.sender, rewardAmount);
    }

    function harvest() public nonReentrant {
        _harvest();
    }

    function emergencyWithdraw() external nonReentrant {
        totalStaked -= stakedAmount[msg.sender];
        emit Withdraw(msg.sender, stakedAmount[msg.sender]);
        stakingToken.transfer(msg.sender, stakedAmount[msg.sender]);
        stakedAmount[msg.sender] = 0;
    }

    function unclaimedRewards(address staker) external view returns (uint256) {
        if (stakingTimestamps[staker] == 0 || stakedAmount[staker] == 0) { return 0; }
        return (block.timestamp - stakingTimestamps[staker]) * rewardPerSecond * stakedAmount[staker] / totalStaked;
    }

    //ADMIN
    function changeVars(bool _stakingPaused, uint256 _stakingPeriod, uint256 _rewardPoolSize, address _stakingToken, address _rewardToken, uint256 _taxFee) external onlyOwner {
        require(stakingPaused || (totalStaked == 0), "Staking started");
        require(_taxFee <= 2500, "Tea party");
        if (stakingPeriod != _stakingPeriod) { stakingPeriod = _stakingPeriod; }
        if (rewardPoolSize != _rewardPoolSize) { rewardPoolSize = _rewardPoolSize; }
        if ((stakingPeriod != _stakingPeriod) || (rewardPoolSize != _rewardPoolSize)) {  rewardPerSecond = (_rewardPoolSize/_stakingPeriod); }
        if (address(stakingToken) != _stakingToken) { stakingToken = IERC20(_stakingToken); }
        if (address(rewardToken) != _rewardToken) { rewardToken = IERC20(_rewardToken); }
        if (stakingPaused != _stakingPaused) { stakingPaused = _stakingPaused; }
        if (taxFee != _taxFee) { taxFee = _taxFee; }
    }

    function theTaxMan() external onlyOwner {
        stakingToken.transfer(msg.sender, stakingToken.balanceOf(address(this)) - totalStaked);
        taxesHeld = 0;
    }


    //EMERGENCY ONLY
    function recoverToken(address _token, uint256 amount) external virtual onlyOwner {
        require(_token != address(stakingToken), "No ruggaroo");
        IERC20(_token).transfer(owner(), amount);
    }

}