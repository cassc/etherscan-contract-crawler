// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeBitcoinxEarnBTCX is ReentrancyGuard{
    address public owner;
    address payable public wallet;
    uint256 public baseFee = 1000000000000000; //wei

    uint256 public penalty = 5;
    uint256 public totalStakedAmount;
    uint256 public totalRewardSent;
    uint256 public totalStakers;

    mapping(address => uint256) public stakeBalances;
    mapping(address => uint256) public rewardBalances;
    mapping(address => uint256) public rewardPaidBalances;
    mapping(address => uint256) public stakedDates;
    mapping(address => uint256) public lastStakedDates;
    mapping(address => uint256) public lockedDurations;

    uint256 public rewardPerBlock = 40000000000000000; //wei in USD Per 1M BTCX (0.04 per block/1M) 
    uint256 public baseShare = 1000000000000000000000000; //1M BTCX
    
    ERC20 public stakeToken;
    ERC20 public rewardToken;

    event Staked(address indexed user, uint256 amount);
    event UnStaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address payable _wallet, ERC20 _stakeToken, ERC20 _rewardToken){
        require(_wallet != address(0));
        wallet = _wallet;
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;       
        owner = msg.sender;
    }

    function doStake(uint256 amount) external nonReentrant{
         _updateReward(msg.sender);
        require(stakeToken.balanceOf(msg.sender) > 0 , "Insuficient Token");
        if(rewardBalances[msg.sender] > 0){
            ERC20(rewardToken).transfer(msg.sender, rewardBalances[msg.sender]);
            emit RewardPaid(msg.sender, rewardBalances[msg.sender]);
            rewardPaidBalances[msg.sender] += rewardBalances[msg.sender];
            totalRewardSent += rewardBalances[msg.sender];
            rewardBalances[msg.sender] = 0;
        }
        
        ERC20(stakeToken).transferFrom(msg.sender, address(this), amount);  
        emit Staked(msg.sender, amount);
        if(stakeBalances[msg.sender] == 0){
            totalStakers += 1;
            stakedDates[msg.sender] = block.timestamp;
        }
        stakeBalances[msg.sender] += amount;        
        lastStakedDates[msg.sender] = block.timestamp;
        lockedDurations[msg.sender] = block.timestamp + 90 days;
        totalStakedAmount += amount;
                
    }

    function claimReward(uint256 amount) external payable nonReentrant{
        require(amount >= baseFee, 'Low Gas Fee');
        _updateReward(msg.sender);
        if(rewardBalances[msg.sender] > 0){
            ERC20(rewardToken).transfer(msg.sender, rewardBalances[msg.sender]);
            emit RewardPaid(msg.sender, rewardBalances[msg.sender]);
            rewardPaidBalances[msg.sender] += rewardBalances[msg.sender];
            totalRewardSent += rewardBalances[msg.sender];
            rewardBalances[msg.sender] = 0;
        }
        lastStakedDates[msg.sender] = block.timestamp;
        wallet.transfer(msg.value);
    
    }

    function unStakeToken(uint256 amount) external payable nonReentrant{
        require(amount >= baseFee, 'Low Gas Fee');
        _updateReward(msg.sender);
        if(block.timestamp < lockedDurations[msg.sender]){
            uint256 penaltyAmount = stakeBalances[msg.sender]*penalty/100; 
            totalStakedAmount -=  stakeBalances[msg.sender];          
            ERC20(stakeToken).transfer(wallet, penaltyAmount);
            ERC20(stakeToken).transfer(msg.sender, stakeBalances[msg.sender] - penaltyAmount);
            emit UnStaked(msg.sender, stakeBalances[msg.sender] - penaltyAmount);
            stakeBalances[msg.sender] = 0;

            ERC20(rewardToken).transfer(msg.sender, rewardBalances[msg.sender]);
            emit RewardPaid(msg.sender, rewardBalances[msg.sender]);

            rewardPaidBalances[msg.sender] += rewardBalances[msg.sender];
            totalRewardSent += rewardBalances[msg.sender];
            rewardBalances[msg.sender] = 0;
            
            
        }else{
            ERC20(stakeToken).transfer(msg.sender, stakeBalances[msg.sender]);
            emit UnStaked(msg.sender, stakeBalances[msg.sender]);
            totalStakedAmount -=  stakeBalances[msg.sender]; 
            stakeBalances[msg.sender] = 0;

            ERC20(rewardToken).transfer(msg.sender, rewardBalances[msg.sender]);
            emit RewardPaid(msg.sender, rewardBalances[msg.sender]);
            rewardPaidBalances[msg.sender] += rewardBalances[msg.sender];
            totalRewardSent += rewardBalances[msg.sender];
            rewardBalances[msg.sender] = 0;            
        }
        totalStakers -= 1;
        wallet.transfer(msg.value);
    }

    function getUserStakedToken(address _address) public view returns(uint256){
        return stakeBalances[_address];
    }

    function getUserCurrentReward(address _address) public view returns(uint256){
        return earned(_address);
    }

    function getUserStakedDate(address _address) public view returns(uint256){
        return stakedDates[_address];
    }

    function getUserRewardPaidBalances(address _address) public view returns(uint256){
        return rewardPaidBalances[_address];
    }

    function getUserLockedDurations(address _address) public view returns(uint256){
        return lockedDurations[_address];
    } 

    function getTotalRewardTokenInSmartContract() public view returns(uint256){
        return rewardToken.balanceOf(address(this));
    }


    function getTotalStakers() public view returns(uint256){
        return totalStakers;
    }

    function getTotalRewardSent() public view returns(uint256){
        return totalRewardSent;
    }

    function getTotalStakedAmount() public view returns(uint256){
        return totalStakedAmount;
    }

    function withdrawFund(uint amount) external onlyOwner{
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
    
    function transferRewardToken(address to, uint256 amount) public onlyOwner {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        require(amount <= tokenBalance, "balance is low");
        rewardToken.transfer(to, amount);
    }

    function transferStakeToken(address to, uint256 amount) public onlyOwner {
        uint256 tokenBalance = stakeToken.balanceOf(address(this));
        require(amount <= tokenBalance, "balance is low");
        stakeToken.transfer(to, amount);
    }  

    function setStakeToken(ERC20 _stakeToken) public onlyOwner{
        stakeToken = _stakeToken;
    }

    function setRewardToken(ERC20 _rewardToken) public onlyOwner{
        rewardToken = _rewardToken;
    }

    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }

    function setBaseShare(uint256 _baseShare) public onlyOwner {
        baseShare = _baseShare;
    }

    function setPenalty(uint256 _penalty) public onlyOwner {
        penalty = _penalty;
    }

    function rewardPerShare(address _address, uint256 totalBlock) public view returns (uint256) {
        uint256 share = stakeBalances[_address]/baseShare;
        uint256 earnedUSD = share * totalBlock * rewardPerBlock;
        return earnedUSD;   
    }

    function getUserShare(address _address) public view returns (uint256) {
        return stakeBalances[_address]/baseShare;
    }

    function earned(address account) public view returns (uint256) {
        //calculate the block timestime
        require(block.timestamp > lastStakedDates[account], 'Incorrect Timestamp');
        uint256 totalSecond = block.timestamp - lastStakedDates[account];
        uint256 totalBlock = totalSecond/3;
        uint256 earnedReward = rewardPerShare(account, totalBlock);
        return earnedReward;
    }

    function getAllRewardEarnedByUser(address account) public view returns (uint256) {
        require(block.timestamp > stakedDates[account], 'Incorrect Timestamp');
        uint256 totalSecond = block.timestamp - stakedDates[account];
        uint256 totalBlock = totalSecond/3;
        uint256 earnedReward = rewardPerShare(account, totalBlock);
        return earnedReward;
    }

    function modifyStakeDate(address _address, uint256 _createdDate) external onlyOwner {
        stakedDates[_address] = _createdDate;
    }

    function _updateReward(address _address) internal{
       rewardBalances[_address] = earned(_address);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }

    function transferOwnership(address _address) public onlyOwner {
        require(_address != address(0), "Invalid Address");
        owner = _address;
    }
}