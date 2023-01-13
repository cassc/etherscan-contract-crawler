// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/LOYALTY.sol";


// File: HachiStaker.sol
contract HachiStaker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 userId;
        uint256 amount;
        uint256 rewardEarned;
        uint256 depositTime;
    }

 
    /* Info of pool:
    stakeToken: The address of Stake token contract.
    periodRewardTokenCount: number of reward tokens per reward period
    lastMassUpdate: last calculation of rewards for all the users
    poolTotalSupply: the total number of staked tokens in the contract
     */

    struct PoolInfo {
        IERC20 stakeToken;
        uint256 periodRewardTokenCount;
        uint256 lastMassUpdate;
        uint256 poolTotalSupply;
    }

    uint constant rewardDuration = 60; // Every 60 seconds
    uint private calculationFactor = 10**5;
    uint private minimumBalance = 1000000**5;
    string constant public lockPeriod = '1 week';  // locked period in text to be shown by the GUI
    uint256 private contractLockPeriod = 604800; // 1 week in seconds 
    address public rewardTokenAddress;
    // Info of pool.
    PoolInfo public poolInfo;

    // Info of each user that stakes Stake tokens.
    uint256 private userCount = 0;
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => address) private userMapping;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount
    );

    constructor(
        IERC20 _stakeToken,
        uint256 _periodRewardTokenCount
    ) {
        /*
        @dev - single pool staking contract
        */ 
        poolInfo.stakeToken = _stakeToken;
        poolInfo.periodRewardTokenCount = _periodRewardTokenCount;
        poolInfo.lastMassUpdate = block.timestamp;
        poolInfo.poolTotalSupply = 0;
    }

    
    function setRewardTokenAddress(address _rewardToken) external onlyOwner {
        rewardTokenAddress = _rewardToken;
    }


    /*
    * Pool daily rewards token count
    */
    function getPeriodRewardTokenCount() public view onlyOwner returns(uint256) {
        return poolInfo.periodRewardTokenCount;
    }

    /*
    * returns total number of staked token
    */
    function getPoolTotalStakedSupply() public view returns(uint256) {
        return poolInfo.poolTotalSupply;
    }

    /*
    * set number of reward token for one reward period
    */
    function setPoolRewardTokenCount(uint256 _rewardTokenCount) public onlyOwner {
        poolInfo.periodRewardTokenCount = _rewardTokenCount;
    }
    
    /*
    * returns the calculation factor
    */
    function getCalculationFactor() public view onlyOwner returns(uint) {
        return calculationFactor;
    }

    /*
    * sets the calculation factor
    */
    function setCalculationFactor(uint _calculationFactor) public onlyOwner {
        calculationFactor = _calculationFactor;
    }

    /*
    * Returns the remaining lock period for a user
    */
    function remainLockTime(address _user) 
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 timeElapsed = block.timestamp.sub(user.depositTime);
        uint256 remainingLockTime = 0;
        if (user.depositTime == 0) {
            remainingLockTime = 0;
        } else if(timeElapsed < contractLockPeriod) {
            remainingLockTime = contractLockPeriod.sub(timeElapsed);
        }

        return remainingLockTime;
    }

    /*
    * The mass update calculates the earned rewards for all the user until the current timestamp and 
    * stores the results in the userInfo.
    * This is necessary on any change to any user blance i.e. (deposite, withdrawal, emergencyWithdraw)
    * Also needed on claim as the userInfo needs to be updated. 
    */
    function _MassUpdate() internal {
        PoolInfo storage pool = poolInfo; 
        uint256 _updateTime = block.timestamp;
        uint256 reward;

        // Do not calculte before reward duration
        if (_updateTime.sub(pool.lastMassUpdate) >= rewardDuration) {
            for (uint256 i = 1; i <= userCount; i++) {
                reward = claimableReward(userMapping[i], _updateTime);
                UserInfo storage user = userInfo[userMapping[i]];
                user.rewardEarned = user.rewardEarned.add(reward);
            }
            pool.lastMassUpdate = _updateTime;
           
        }
    }

    /*
    * View function to see pending reward tokens on frontend.
    */
    function claimableReward(address _user, uint256 _calculationTime)
        public
        view
        returns (uint256)
    {
        // update all user reward and save 
        PoolInfo storage pool = poolInfo; 
        UserInfo storage user = userInfo[_user];
        
        uint256 totalSupply = pool.poolTotalSupply;
        uint256 duration;
        uint durationCount;
        uint256 rewardTokenCount;
        if (_calculationTime == 0) {
            _calculationTime = block.timestamp;
        }
        
        if (_calculationTime > pool.lastMassUpdate && totalSupply > 0) {
            duration = _calculationTime.sub(pool.lastMassUpdate);
            durationCount = duration.div(rewardDuration); 
            rewardTokenCount = durationCount.mul(pool.periodRewardTokenCount); 
        }

        uint userPercent = 0;
        if (totalSupply != 0) {
            userPercent = user.amount.mul(calculationFactor).div(totalSupply);
        }

        uint256 userReward = userPercent.mul(rewardTokenCount).div(calculationFactor);

        return userReward;
    }

    /*
    * Deposit tokens into the contract.
    * Also triggers a MassUpdate to ensure correct calculation of earned rewards.
    * Important! Make sure to pass amount in wei  (10**18)
    */
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo; 
        UserInfo storage user = userInfo[msg.sender];

        _MassUpdate(); // Update and store the earned reward before a new deposit

        user.rewardEarned = user.rewardEarned.add(claimableReward(msg.sender, 0));
        
        // reset user deposit time if the balance less than the minimumBalance
        if (user.amount <= minimumBalance) { 
            user.depositTime = block.timestamp;
        }

        pool.stakeToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);

        // if new user, increase user count
        if (user.userId == 0) {
            userCount = userCount.add(1);
            user.userId = userCount;
            userMapping[userCount] = msg.sender;
        }
        pool.poolTotalSupply = pool.poolTotalSupply.add(_amount);

        emit Deposit(msg.sender, _amount);
    }

    /*
    * Withdraws staked tokens if the locked period has passed.
    * If locked period is not passed, this function fail. 
    * To withdraw before locked period is finished, call emergencyWithdraw()
    * Also triggers a MassUpdate to ensure correct calculation of earned rewards.
    * Important! Make sure to pass amount in wei  (10**18)
    */
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        uint256 remainLock = remainLockTime(msg.sender);

        require(user.amount >= _amount, "withdraw: the requested amount exceeds the balance!");
        require(remainLock <= 0, "withdraw: locktime remains!");

        _MassUpdate();
        user.rewardEarned = user.rewardEarned.add(claimableReward(msg.sender, 0));
        user.amount = user.amount.sub(_amount);

        pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        pool.poolTotalSupply = pool.poolTotalSupply.sub(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    /*
    * Withdraw the staked token before the lock period is finished.
    * User rewards will be losed.
    */
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo; 
        UserInfo storage user = userInfo[msg.sender];
        
        // calculates the reward the user have earned so far
        _MassUpdate();
        user.rewardEarned = user.rewardEarned.add(claimableReward(msg.sender, 0));
    
        // retuns the staked tokens to the user
        pool.stakeToken.safeTransfer(address(msg.sender), user.amount);
        pool.poolTotalSupply = pool.poolTotalSupply.sub(user.amount);

        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardEarned = 0;
    }

    /*
    * returns the pending rewards for the user.
    */
    function claim() external {
        uint256 remainLock = remainLockTime(msg.sender);
        require(remainLock <= 0, "claim: locktime remain");

        // update user rewards
        UserInfo storage user = userInfo[msg.sender];
        _MassUpdate();

       
        
        // Mint the reward token and transfer to msg.sender
        if (user.rewardEarned > 0) {
            LOYALTY(rewardTokenAddress).mint(msg.sender,user.rewardEarned);
        }
        user.rewardEarned = 0;
    }

}