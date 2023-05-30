// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakingPrivateUniV2 is ReentrancyGuard, Ownable, Pausable {
    IERC20Metadata private stakingToken;
    IERC20Metadata private rewardToken;
    uint32 private participationCode;

    constructor(address _stakingToken, address _rewardToken, uint32 _participationCode) onlyOwner {
        stakingToken = IERC20Metadata(_stakingToken);
        rewardToken = IERC20Metadata(_rewardToken);
        participationCode = _participationCode;
    }

    struct Staker {
        uint256 amount;
        uint256 startTime;
        uint256 withdrawalTime;
        uint256 totalRewardAmount;
    }

    mapping(address => Staker) private stakers;
    mapping(address => Staker[]) public stakerArray;
    mapping(address => uint256) public totalStakedAmount;
    mapping(address => uint256) public totalRewardReleased;

    uint256 public constant hanTokenPerLpToken = 694953927154714;
    uint256 public tokenQuota = 10000 ether;
    uint256 public totalSupply; 

    // "STAKE" function
    function stake(uint32 _participationCode, uint256 _amount) public nonReentrant whenNotPaused {
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Cannot stake 0");
        require(_amount + totalSupply <= tokenQuota, "Too Many Token");
        require(_participationCode == participationCode, "Invalid participationCode");
        require(rewardToken.balanceOf(address(this)) > _amount * hanTokenPerLpToken * 365 days / 10**18, "Total amount of rewards is too high");
        totalSupply += _amount;
        totalStakedAmount[msg.sender] += _amount;
        staker.amount = _amount;
        staker.startTime = block.timestamp;
        // staker.withdrawalTime = block.timestamp + 365 days;
        // staker.totalRewardAmount = amount * hanTokenPerLpToken * 365 days / 10**18;
        staker.withdrawalTime = block.timestamp + 60;
        staker.totalRewardAmount = _amount * hanTokenPerLpToken * 60 / 10**18;
        stakerArray[msg.sender].push(staker);
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // "WITHDRAW" function
    function withdraw(uint256 _index) public nonReentrant {
        Staker storage stakerArr = stakerArray[msg.sender][_index];
        require(block.timestamp > stakerArr.withdrawalTime, "It's not the time to withdraw");
        if (stakerArr.totalRewardAmount > 0) { // Expired amounts include rewards and are transferred.
            claimReward(); 
        }
        totalSupply -= stakerArr.amount;
        totalStakedAmount[msg.sender] -= stakerArr.amount;
        stakingToken.transfer(msg.sender, stakerArr.amount);
        emit Withdrawn(msg.sender, stakerArr.amount);
        removeElement(_index);
    }

// "CLAIM" function
    function claimReward() public {
        uint256 reward;
        for(uint i = 0; i < stakerArray[msg.sender].length; i++) {
            uint256 rewardValue = (block.timestamp - stakerArray[msg.sender][i].startTime) * (stakerArray[msg.sender][i].amount * hanTokenPerLpToken / 10**18);
            if (rewardValue > stakerArray[msg.sender][i].totalRewardAmount) {
                rewardValue = stakerArray[msg.sender][i].totalRewardAmount; 
            }
            if (rewardValue > 0) {
                reward += rewardValue;
                stakerArray[msg.sender][i].totalRewardAmount -= rewardValue;
                stakerArray[msg.sender][i].startTime = block.timestamp;
            }
        }
        if (reward > 0) {
            rewardToken.transfer(msg.sender, reward);
            totalRewardReleased[msg.sender] += reward;
            emit RewardPaid(msg.sender, reward);
        }
        if (reward == 0) {
            revert("There's no reward for your claim");
        }
    }

    function remainingDuration(address _user, uint256 _index) public view returns (uint256) {
        if(stakerArray[_user][_index].withdrawalTime >= block.timestamp) {
            return stakerArray[_user][_index].withdrawalTime - block.timestamp;
        } else {
            return 0;
        }
    }

    // Current Rewardable Amount Output Function
    function rewardView(address _user) public view returns(uint256) {
        uint256 reward;
        for(uint256 i = 0; i < stakerArray[_user].length; i++) {
            uint256 rewardValue = (block.timestamp - stakerArray[_user][i].startTime) * (stakerArray[_user][i].amount * hanTokenPerLpToken / 10**18);
            if (rewardValue > stakerArray[_user][i].totalRewardAmount) {
                rewardValue = stakerArray[_user][i].totalRewardAmount; // Limit the reward to totalRewardAmount
            }
            if (rewardValue > 0) {
                reward += rewardValue;
            }
        }
        return reward;
    }

    function getStakerArray(address _user) public view returns(Staker[] memory) {
        return stakerArray[_user];
    }

    function getParticipationCode() public view onlyOwner returns (uint32) {
        return participationCode;
    }

    function setParticipationCode(uint32 _newParticipationCode) public onlyOwner {
        require(participationCode != _newParticipationCode, "Same particiationCode");
        participationCode = _newParticipationCode;
    }

    function setTokenQuota(uint256 _newTokenQuota) public onlyOwner {
        require(_newTokenQuota > totalSupply, "Too Small Quota");
        tokenQuota = _newTokenQuota;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this),msg.sender,_tokenId);
        emit RecoveredERC721(_tokenAddress, _tokenId);
    }


    function removeElement(uint256 _index) internal {
        require(_index < stakerArray[msg.sender].length, "Invalid index");
        stakerArray[msg.sender][_index] = stakerArray[msg.sender][stakerArray[msg.sender].length - 1];
        stakerArray[msg.sender].pop();
    }

    // ------------------ EVENTS ------------------ //

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
}