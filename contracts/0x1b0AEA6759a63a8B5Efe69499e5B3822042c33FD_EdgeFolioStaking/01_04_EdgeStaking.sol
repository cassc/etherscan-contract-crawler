// SPDX-License-Identifier: MIT
// Edge Folio Staking Contract
pragma solidity 0.8.21;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract EdgeFolioStaking is Ownable {

    IERC20 public edgeFolio;
    uint256 public lastRewardTimestamp;
    uint256 public rewardPerSecond;
    uint256 public rewardSupply;
    
    uint256 accTokenPerShare;
    
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 startTime;
        uint256 totalRewards;
    }
    
    mapping(address => UserInfo) public userInfo;
    
    uint256 public totalStakedAmount;
    uint256 public startTime;
    bool public isStarted;
    bool public isFinished;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC20 _edgeFolio, uint256 _rewardPerSecond) {
        edgeFolio = _edgeFolio;
        rewardPerSecond = _rewardPerSecond;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 balance = totalStakedAmount;
        if (block.timestamp > lastRewardTimestamp && balance != 0) {
            uint256 tokenReward = (block.timestamp - lastRewardTimestamp) * rewardPerSecond;
            _accTokenPerShare += (tokenReward * 1e36 / balance);
        }
        return (user.amount * _accTokenPerShare / 1e36) - user.rewardDebt;
    }

    function updatePool() public {
        uint256 timestamp = block.timestamp;
        if (!isStarted) {
            revert("Has not started yet");
        }
        if (timestamp <= lastRewardTimestamp) {
            return;
        }
        uint256 _totalStakedAmount = totalStakedAmount;
        if (_totalStakedAmount == 0) {
            lastRewardTimestamp = timestamp;
            return;
        }
        uint256 reward = (timestamp - lastRewardTimestamp) * rewardPerSecond;
        accTokenPerShare += (reward * 1e36 / _totalStakedAmount);
        lastRewardTimestamp = timestamp;
        rewardSupply += reward;
    }

    function _claimRewards(uint256 amount, uint256 rewardDebt) internal returns (uint256 amountToSend) {
        uint256 totalRewards = (amount * accTokenPerShare / 1e36) - rewardDebt;
        uint bal = edgeFolio.balanceOf(address(this)) - totalStakedAmount;
        amountToSend = totalRewards > bal ? bal : totalRewards;
        IERC20(edgeFolio).transfer(msg.sender, amountToSend);
        rewardSupply -= totalRewards;
        emit RewardClaimed(msg.sender, totalRewards);
    }

    function deposit(uint256 _tokenAmount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 amountTransferred = _claimRewards(user.amount, user.rewardDebt);
            user.totalRewards += amountTransferred;
        }
        if (_tokenAmount > 0) {
            edgeFolio.transferFrom(address(msg.sender), address(this), _tokenAmount);
            //for apy calculations
            if (user.amount == 0) {
                user.startTime = block.timestamp;
                user.totalRewards = 0;
            }
            //update balances
            user.amount += _tokenAmount;
            totalStakedAmount += _tokenAmount;
            emit Deposit(msg.sender, _tokenAmount);
        }
        user.rewardDebt = user.amount * accTokenPerShare / 1e36;
    }

    function withdraw(uint256 _tokenAmount) external {
        UserInfo storage user = userInfo[msg.sender];
        if (_tokenAmount > user.amount) {
            revert("Insufficient balance!");
        }
        updatePool();
        if (user.amount > 0) {
            uint256 amountTransferred = _claimRewards(user.amount, user.rewardDebt);
            user.totalRewards += amountTransferred;
        }
        if (_tokenAmount > 0) {
            user.amount -= _tokenAmount;
            edgeFolio.transfer(address(msg.sender), _tokenAmount);
            totalStakedAmount -= _tokenAmount;
            emit Withdraw(msg.sender, _tokenAmount);
        }
        user.rewardDebt = user.amount * accTokenPerShare / 1e36;
    }

    function setRewardRate(uint256 _rewardPerSecond) external onlyOwner {
        if (isFinished) {
            revert("Already finished!");
        }
        rewardPerSecond = _rewardPerSecond;
    }

    function startPool(uint256 _startTime) external onlyOwner {
        if (isStarted) {
            revert("Already started!");
        }
        isStarted = true;
        startTime = _startTime;
        lastRewardTimestamp = _startTime;
    }

    function finishPool() external onlyOwner {
        if (isFinished) {
            revert("Already finished!");
        }
        isFinished = true;
        updatePool();
        rewardPerSecond = 0;
        
        if (totalStakedAmount > rewardSupply) {
            IERC20(edgeFolio).transfer(owner(), totalStakedAmount - rewardSupply);
        }
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}