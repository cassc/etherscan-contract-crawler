//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RMCVest is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Lock {
        uint initialAmount;
        uint amount;
        uint lockedAt;
        uint unlockedAt;
        uint lockPeriod;
        uint unlockCycle;
        uint unlockPercent;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 claimedAt;
    }

    IERC20 public immutable token;

    mapping (address => Lock[]) public vests;
    mapping(address => UserInfo) public users;

    uint256 public lastUpdateTime;
    uint256 public accPerShare;
    uint256 public totalSupply;
    uint256 public totalReward;
    uint256 public constant rewardRate = 1 ether;
    uint256 public rewardCycle = 24 hours;

    constructor(address _token) {
        token = IERC20(_token);
        lastUpdateTime = block.timestamp;
    }

    function count(address _wallet) public view returns (uint) {
        return vests[_wallet].length;
    }

    function updateReward(address _wallet) internal {
        if (totalSupply > 0) {
            uint256 multiplier = block.timestamp - lastUpdateTime;
            uint256 reward = multiplier * rewardRate;
            totalReward = totalReward + (multiplier * rewardRate);
            accPerShare = accPerShare + (reward * 1e12 / totalSupply);
        }
        lastUpdateTime = block.timestamp;

        UserInfo storage user = users[_wallet];
        uint256 pending = (user.amount * accPerShare / 1e12) - user.rewardDebt;
        user.pendingRewards = user.pendingRewards + pending;
    }

    function singleVest(
        address _wallet, 
        uint _amount, 
        uint _lockPeriod, 
        uint _unlockCycle, 
        uint _unlockPercent
    ) public nonReentrant {
        require (_amount > 0, "!amount");
        require (_lockPeriod > _unlockCycle, "!unlock cycle");
        require (_unlockPercent > 0 && _unlockPercent <= 100, "!unlock percent");

        uint before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        require (_amount == token.balanceOf(address(this)) - before, "taxed");

        vests[_wallet].push(Lock({
            initialAmount: _amount,
            amount: _amount,
            lockedAt: block.timestamp,
            unlockedAt: block.timestamp,
            lockPeriod: _lockPeriod,
            unlockCycle: _unlockCycle,
            unlockPercent: _unlockPercent
        }));

        updateReward(_wallet);

        totalSupply += _amount;

        UserInfo storage user = users[_wallet];
        user.amount += _amount;
        user.rewardDebt = user.amount * accPerShare / 1e12;
        if (user.claimedAt == 0) user.claimedAt = block.timestamp;
    }

    function selfVest(
        uint _amount, 
        uint _lockPeriod, 
        uint _unlockCycle, 
        uint _unlockPercent
    ) external {
        singleVest(msg.sender, _amount, _lockPeriod, _unlockCycle, _unlockPercent);
    }

    function multipleVest(
        address[] calldata _wallets, 
        uint[] calldata _amounts, 
        uint _lockPeriod, 
        uint _unlockCycle, 
        uint _unlockPercent
    ) external nonReentrant {
        require (_lockPeriod > _unlockCycle, "!unlock cycle");
        require (_unlockPercent > 0 && _unlockPercent <= 100, "!unlock percent");
        require (_wallets.length == _amounts.length, "!count");

        uint totalAmount;
        for (uint i = 0; i < _amounts.length; i++) {
            require (_amounts[i] > 0, "!amount");
            totalAmount += _amounts[i];
        }

        uint before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), totalAmount);
        require (totalAmount == token.balanceOf(address(this)) - before, "taxed");

        if (totalSupply > 0) {
            uint256 multiplier = block.timestamp - lastUpdateTime;
            uint256 reward = multiplier * rewardRate;
            totalReward = totalReward + (multiplier * rewardRate);
            accPerShare = accPerShare + (reward * 1e12 / totalSupply);
        }

        for (uint i = 0; i < _wallets.length; i++) {
            vests[_wallets[i]].push(Lock({
                initialAmount: _amounts[i],
                amount: _amounts[i],
                lockedAt: block.timestamp,
                unlockedAt: block.timestamp,
                lockPeriod: _lockPeriod,
                unlockCycle: _unlockCycle,
                unlockPercent: _unlockPercent
            }));

            UserInfo storage user = users[_wallets[i]];
            user.amount += _amounts[i];
            user.rewardDebt = user.amount * accPerShare / 1e12;
            if (user.claimedAt == 0) user.claimedAt = block.timestamp;
        }

        totalSupply += totalAmount;
        lastUpdateTime = block.timestamp;
    }

    function unlock(uint _index) external nonReentrant {
        Lock[] storage locks = vests[msg.sender];
        require (locks.length > 0, "!vested");
        require (locks.length > _index, "!index");

        Lock storage lock = locks[_index];
        require (block.timestamp - lock.lockedAt > lock.lockPeriod, "!available unlock");
        require (block.timestamp - lock.unlockedAt > lock.unlockCycle, "!next unlock time");

        uint unlockAmount = lock.initialAmount * lock.unlockPercent / 100;

        token.safeTransfer(msg.sender, unlockAmount);

        if (unlockAmount >= lock.amount) {
            locks[_index] = locks[locks.length-1];
            locks.pop();
        } else {
            lock.unlockedAt = block.timestamp;
            lock.amount -= unlockAmount;
        }

        updateReward(msg.sender);

        totalSupply -= unlockAmount;

        UserInfo storage user = users[msg.sender];
        user.amount -= unlockAmount;
        user.rewardDebt = user.amount * accPerShare / 1e12;
    }

    function claim() external nonReentrant {
        UserInfo storage user = users[msg.sender];
        require (user.amount > 0, "!vested");
        require (block.timestamp - user.claimedAt >= rewardCycle, "!available");

        updateReward(msg.sender);

        if (user.pendingRewards > 0) {
            uint rewardAmount = address(this).balance * user.pendingRewards / totalReward;
            require (address(this).balance >= rewardAmount, "!rewards");
            address(msg.sender).call{value: rewardAmount}("");

            totalReward = totalReward - user.pendingRewards;
            user.pendingRewards = 0;
            user.claimedAt = block.timestamp;
        }
    }

    function claimable(address _wallet) external view returns (uint) {
        UserInfo storage user = users[_wallet];
        if (totalSupply == 0 || user.amount == 0) return 0;

        uint256 multiplier = block.timestamp - lastUpdateTime;
        uint256 reward = multiplier * rewardRate;
        uint256 newTotalReward = totalReward - user.pendingRewards;
        uint256 newAccPerShare = accPerShare + (reward * 1e12 / totalSupply);
        uint256 pending = (user.amount * newAccPerShare / 1e12) - user.rewardDebt;
        
        return address(this).balance * (user.pendingRewards + pending) / newTotalReward;
    }

    function setRewardCycle(uint256 _cycleMinutes) external onlyOwner {
        rewardCycle = _cycleMinutes * 1 minutes;
    }
}