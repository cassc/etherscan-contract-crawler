// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ITresuary.sol";
import "./IRewardWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";



contract ArborStakingFixedTimeRBA2Years is Ownable , Pausable{

    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public userEndTime;
    

    uint256 public constant YEAR_SECOND = 31577600;

    uint256 public rewardRate = 12;
    uint256 public oldRewardRate;
    uint256 public rewardRateUpdatedTime;
    uint256 public lockTime;

    bool public isTresuarySet;
    bool public isRewardWalletSet;

    ITresuary public tresuary;
    IRewardWallet public rewardWallet;
       
    IERC20 public stakingToken;
    IERC20 public rewardsToken;
    

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event RewardsWithdrawal(address indexed to, uint256 amount);
    event LogSetRewardRate(uint256 oldRate, uint256 newRate);
    event LogSetTresuary(address newTresuary);
    event LogSetRewardWallet(address newRewardWallet);


    constructor(address _stakingToken, address _rewardsToken, uint256 _lockTime) {
        require(_stakingToken != address(0), "StakingToken Address 0 validation");
        require(_rewardsToken != address(0), "RewardsToken Address 0 validation");

        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        lockTime = _lockTime;
    }

    
    function stake(uint256 amount) public whenNotPaused{
        require(amount > 0, "Can't be 0");
        require(amount > 0 && stakingToken.balanceOf(msg.sender) >= amount, "Incufficient stakingToken balance");

        if(isStaking[msg.sender] == true){
            uint256 toTransfer = getTotalRewards(msg.sender);
            userRewards[msg.sender] += toTransfer;
        }

        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        userEndTime[msg.sender] = block.timestamp + (lockTime * 1 days);

        tresuary.deposit(msg.sender, amount);

        emit Stake(msg.sender, amount);
    }


    function unstake(uint256 amount) public whenNotPaused{
        require(amount > 0, "Can't be 0");
        require(block.timestamp > userEndTime[msg.sender], "Can't unstake yet");
        require(isStaking[msg.sender] = true && stakingBalance[msg.sender] >= amount, "Nothing to unstake");

        uint256 rewards = getTotalRewards(msg.sender);

        startTime[msg.sender] = block.timestamp;
        stakingBalance[msg.sender] -= amount;
        userRewards[msg.sender] += rewards;

        if(stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }

        tresuary.withdraw(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }


    function getTotalTime(address user) public view returns(uint256){
        uint256 finish = block.timestamp;
        uint256 totalTime = finish - startTime[user];
        return totalTime;
    }


    function getTotalRewards(address user) public view returns(uint256) {
        
        if (stakingBalance[user] > 0) {
             uint256 newRewards = ((block.timestamp - startTime[user]) * stakingBalance[user] * rewardRate) /
             (YEAR_SECOND * 100);
            return newRewards + userRewards[user];
        }
       
    } 

    function getPendingRewards(address user) public view returns (uint256) {
        return userRewards[user];
    }

    function calculateRewards(uint256 _start, uint256 _amount) public view returns (uint256) {
        uint256 newRewards = ((block.timestamp - _start) * _amount * rewardRate) / (YEAR_SECOND * 100);
        return newRewards;
    }

    function calculateDayRewards(uint256 _start, uint256 _amount) public view returns (uint256) {
        uint256 newRewards = ((_start * 1 days) * _amount * rewardRate) / (YEAR_SECOND * 100);
        return newRewards;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require(rewardRate != _rewardRate, "Already set to this value");
        require(_rewardRate != 0, "Can't be 0");

        rewardRateUpdatedTime = block.timestamp;
        oldRewardRate = rewardRate;
        rewardRate = _rewardRate;   

        emit LogSetRewardRate(oldRewardRate, rewardRate);
    }


    function setTresuary(address _tresuary) external onlyOwner {
        require(address(tresuary) != _tresuary, "Already set to this value");
        require(_tresuary != address(0), "Address 0 validation");
        require(isTresuarySet == false, "Tresuary can be set only once");

        isTresuarySet = true;
        tresuary = ITresuary(_tresuary);

        emit LogSetTresuary(_tresuary);
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner {
        require(address(rewardWallet) != _rewardWallet, "Already set to this value");
        require(_rewardWallet != address(0), "Address 0 validation");
        require(isRewardWalletSet == false, "Tresuary can be set only once");

        isRewardWalletSet = true;
        rewardWallet = IRewardWallet(_rewardWallet);

        emit LogSetRewardWallet(_rewardWallet);
    }

    function getRewardRate() external view returns(uint256){
        return rewardRate;
    }

   
    function withdrawRewards() external whenNotPaused{
        uint256 toWithdraw = getTotalRewards(msg.sender);

        require(toWithdraw > 0 || userRewards[msg.sender] > 0, "Incufficient rewards balance");
            
        uint256 oldBalance = userRewards[msg.sender];
        userRewards[msg.sender] = 0;
        toWithdraw += oldBalance;
        
        startTime[msg.sender] = block.timestamp;
        rewardWallet.transfer(msg.sender, toWithdraw);
        emit RewardsWithdrawal(msg.sender, toWithdraw);
    } 

    function setUnpause() external onlyOwner {
        _unpause();
    }

    function setPause() external onlyOwner {
       _pause();
    }

}