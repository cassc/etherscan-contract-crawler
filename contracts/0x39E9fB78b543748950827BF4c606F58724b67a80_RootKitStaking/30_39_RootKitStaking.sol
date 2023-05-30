// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
From https://raw.githubusercontent.com/sushiswap/sushiswap/master/contracts/MasterChef.sol
Except a million times better
*/

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract RootKitStaking is Owned, TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Emergency();

    struct UserInfo 
    {
        uint256 amountStaked;
        uint256 rewardDebt;
    }

    struct PoolInfo 
    {
        IERC20 token;
        uint256 allocationPoints;
        uint256 lastTotalReward;
        uint256 accRewardPerShare;
    }

    IERC20 public immutable rewardToken;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocationPoints;

    mapping (IERC20 => bool) existingPools;
    uint256 constant maxPoolCount = 20; // to simplify things and ensure massUpdatePools is safe
    uint256 totalReward;
    uint256 lastRewardBalance;

    uint256 public emergencyRecoveryTimestamp;

    constructor(IERC20 _rewardToken)
    {
        rewardToken = _rewardToken;
    }

    function poolInfoCount() external view returns (uint256) 
    {
        return poolInfo.length;
    }

    function addPool(uint256 _allocationPoints, IERC20 _token) public ownerOnly()
    {
        require (address(_token) != address(0) && _token != rewardToken && emergencyRecoveryTimestamp == 0);
        require (!existingPools[_token], "Pool exists");
        require (poolInfo.length < maxPoolCount, "Too many pools");
        existingPools[_token] = true;
        massUpdatePools();
        totalAllocationPoints = totalAllocationPoints.add(_allocationPoints);
        poolInfo.push(PoolInfo({
            token: _token,
            allocationPoints: _allocationPoints,
            lastTotalReward: totalReward,
            accRewardPerShare: 0
        }));
    }

    function setPoolAllocationPoints(uint256 _poolId, uint256 _allocationPoints) public ownerOnly()
    {
        require (emergencyRecoveryTimestamp == 0);
        massUpdatePools();
        totalAllocationPoints = totalAllocationPoints.sub(poolInfo[_poolId].allocationPoints).add(_allocationPoints);
        poolInfo[_poolId].allocationPoints = _allocationPoints;
    }

    function pendingReward(uint256 _poolId, address _user) external view returns (uint256) 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 supply = pool.token.balanceOf(address(this));
        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 _totalReward = totalReward;
        if (balance > lastRewardBalance) {
            _totalReward = _totalReward.add(balance.sub(lastRewardBalance));
        }
        if (_totalReward > pool.lastTotalReward && supply != 0) {
            uint256 reward = _totalReward.sub(pool.lastTotalReward).mul(pool.allocationPoints).div(totalAllocationPoints);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(supply));
        }
        return user.amountStaked.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public 
    {
        uint256 length = poolInfo.length;
        for (uint256 poolId = 0; poolId < length; ++poolId) {
            updatePool(poolId);
        }
    }

    function updatePool(uint256 _poolId) public 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if (pool.lastTotalReward == rewardBalance) {
            return;
        }
        uint256 _totalReward = totalReward.add(rewardBalance.sub(lastRewardBalance));
        lastRewardBalance = rewardBalance;
        totalReward = _totalReward;
        uint256 supply = pool.token.balanceOf(address(this));
        if (supply == 0) {
            pool.lastTotalReward = _totalReward;
            return;
        }
        uint256 reward = _totalReward.sub(pool.lastTotalReward).mul(pool.allocationPoints).div(totalAllocationPoints);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(supply));
        pool.lastTotalReward = _totalReward;
    }

    function deposit(uint256 _poolId, uint256 _amount) public 
    {
        require (emergencyRecoveryTimestamp == 0, "Withdraw only");
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        updatePool(_poolId);
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeRewardTransfer(msg.sender, pending);                
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amountStaked = user.amountStaked.add(_amount);
        }
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _poolId, _amount);
    }

    function withdraw(uint256 _poolId, uint256 _amount) public 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require(user.amountStaked >= _amount, "Amount more than staked");
        updatePool(_poolId);
        uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeRewardTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amountStaked = user.amountStaked.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _poolId, _amount);
    }

    function emergencyWithdraw(uint256 _poolId) public 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        uint256 amount = user.amountStaked;
        user.amountStaked = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _poolId, amount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal 
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(_to, _amount > balance ? balance : _amount);
        lastRewardBalance = rewardToken.balanceOf(address(this));
    }

    function declareEmergency() public ownerOnly() 
    {
        // Funds will be recoverable 3 days after an emergency is declared
        // By then, everyone should have withdrawn whatever they can
        // Failing that (which is probably why there's an emergency) we can recover for them
        emergencyRecoveryTimestamp = block.timestamp + 60*60*24*3;
        emit Emergency();
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        if (emergencyRecoveryTimestamp != 0 && block.timestamp > emergencyRecoveryTimestamp) {
            return true;
        }
        else {
            return token != rewardToken && !existingPools[token];
        }
    }
}