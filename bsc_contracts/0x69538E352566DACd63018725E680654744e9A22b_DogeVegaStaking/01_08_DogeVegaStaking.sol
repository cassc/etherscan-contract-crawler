// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Error.sol";

contract DogeVegaStaking is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public  dogeToken;

    struct StakingInfo {
        address staker;
        uint256 amount;
        uint256 updateAt;
        uint256 startAt;
    }

    // stake id => stake info structure
    mapping(uint256 => StakingInfo) public stakingInfos;

    // address -> staking Ids 
    mapping(address => uint256[]) ownerOfStakingIds;

    //stakeid mappin current rewardAmount
    mapping(uint256 => uint256) public rewardAmount;

    //so far total stakeAmount from all user;
    uint256 public totalStakeAmount;

    //total claimAmount;
    uint256 totalClaimAmount;

    // staking reward percentage out of 100
    uint256 public percentage = 20;
    // staking identifier; start from 1; strictly increasing
    uint256 stakingId = 1;

    event Deposit(address _address,uint256 _amount);
    event Redeem(address _address,uint256 _stakingId,uint256 _amount);
    event Claim(address _address,uint256 _stakingId,uint256 _amount);

    address public stakeToken;
    
    constructor(address _stakingToken) {
        if (_stakingToken == address(0)) revert ZeroAddress();
        dogeToken = IERC20(_stakingToken);
    }

    function setToken(address _stakeToken) external onlyOwner{
        stakeToken = _stakeToken;
    }

    function setPercentage(uint256 _percentage) external onlyOwner{
        if (_percentage > 100) revert InvalidPercentage();
        percentage = _percentage;
    }

    function depositFunds(uint256 _amount) external onlyOwner {
        if(_amount <= 0 ) revert InvalidValue();
        dogeToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function stake(uint256 _amount) external {
        if(_amount <=0 ) revert InvalidValue();
        dogeToken.safeTransferFrom(msg.sender, address(this), _amount);
        totalStakeAmount += _amount;
        StakingInfo memory newInfo= StakingInfo({
            staker: msg.sender,
            amount: _amount,
            updateAt: block.timestamp,
            startAt: block.timestamp
        });
        stakingInfos[stakingId] = newInfo;
        ownerOfStakingIds[msg.sender].push(stakingId);
        stakingId++;
        emit Deposit(msg.sender, _amount);
    }

    function redeem(uint256 _stakingId,uint256 _amount) external {
        if(stakingInfos[_stakingId].staker != msg.sender) revert InCorrectUserAddress();
        if(stakingInfos[_stakingId].amount < _amount) revert InvalidValue();
        if((block.timestamp - stakingInfos[_stakingId].startAt) < 30 days) revert NotEnoughDays();
        dogeToken.safeTransfer(msg.sender, _amount);
        rewardAmount[_stakingId] = _getReward(_stakingId);
        stakingInfos[_stakingId].amount -= _amount;
        stakingInfos[_stakingId].updateAt = block.timestamp;
        emit Redeem(msg.sender,_stakingId,_amount);
    }
    
    function claim(uint256 _stakingId,uint256 _amount) external {
        if(stakingInfos[_stakingId].staker != msg.sender) revert InCorrectUserAddress();
        if(rewardAmount[_stakingId] < _amount) revert InvalidValue();
        if((block.timestamp - stakingInfos[_stakingId].startAt) < 30 days) revert NotEnoughDays();
        totalClaimAmount += _amount;
        dogeToken.safeTransfer(msg.sender, _amount);
        rewardAmount[_stakingId] = _getReward(_stakingId);
        rewardAmount[_stakingId] -= _amount;
        emit Claim(msg.sender,_stakingId,_amount);
    }

    //get user current reward
    function _getReward(uint256 _stakingId) public view returns(uint256){
        uint256 temp =  rewardAmount[_stakingId] + (stakingInfos[_stakingId].amount * uint256((block.timestamp - stakingInfos[_stakingId].updateAt) / 60 / 60 / 24) / 365 * percentage / 100);
        // uint256 temp =  rewardAmount[_stakingId] + (stakingInfos[_stakingId].amount * uint256((block.timestamp - stakingInfos[_stakingId].updateAt)) / 60  * percentage / 100);
        return temp;
    }

    //so far get Total Reward from all users 
    function getTotalReward() public view returns(uint256){
        uint256 temp = totalClaimAmount;
        for(uint256 i = 0 ; i < stakingId ; i++){
            temp += (rewardAmount[i] + (stakingInfos[i].amount * uint256((block.timestamp - stakingInfos[i].updateAt) / 60 / 60 / 24) / 365 * percentage / 100));
            // temp += (rewardAmount[i] + (stakingInfos[i].amount * uint256((block.timestamp - stakingInfos[i].updateAt) / 60 * percentage / 100)));
        }
        return temp;
    }

    //the days from start day to current day
    function getDays(uint256 _stakingId) external view returns(uint256){
        return (block.timestamp - stakingInfos[_stakingId].startAt);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        if(_amount > dogeToken.balanceOf(address(this))) revert InvalidValue();
        dogeToken.safeTransfer(msg.sender,_amount);        
    }

    function getOwnerOfStakingIds(address _address) external view returns(uint256[] memory){
        uint256[] memory temp = ownerOfStakingIds[_address];
        return temp;
    }
}