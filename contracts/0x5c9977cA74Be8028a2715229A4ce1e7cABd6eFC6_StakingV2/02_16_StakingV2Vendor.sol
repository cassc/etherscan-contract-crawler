// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './IStakingV2.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
contract StakingV2Vendor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SuperPoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRealStaked;
        uint256 tokenVirtStaked;
        uint256 tokenRewarded;
        uint256 tokenTotalLimit;
        uint256 lockupMaxTimerange;
        uint256 lockupMinTimerange;
    }

    struct SuperUserInfo {
        uint256 amount;
        uint256 rewardDebt; // backwards compatibility
        uint256 pendingRewards; // backwards compatibility
        uint256 lockedTimestamp;
        uint256 lockupTimestamp;
        uint256 lockupTimerange;
        uint256 virtAmount;
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRewarded;
        uint256 realTokenPerShare;
        uint256 realTokenReceived;
        uint256 realTokenRewarded;
    }

    IERC20 public token;
    IStakingV2 public parent;

    uint256 public tokenPerBlock;
    uint256 public tokenParentPrecision;
    uint256 public startBlock;
    uint256 public closeBlock;
    
    uint256 public maxPid;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event WithdrawnReward(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnRemain(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event TokenAddressChanged(address indexed token);
    event TokenRewardsChanged(address indexed token, uint256 amount);

    event ParentChanged(address indexed addr);
    event StartBlockChanged(uint256 block);
    event CloseBlockChanged(uint256 block);

    constructor(address _parent, IERC20 _token) {
        setParent(_parent);
        setTokenAddress(_token);
        for (uint i=0; i<parent.maxPid(); i++) addPool(i);
        tokenParentPrecision = parent.tokenPerBlock();
    }

    function setParent(address _parent) public onlyOwner {
        require(_parent != address(0), 'Staking: parent address needs to be different than zero!');
        parent = IStakingV2(_parent);
        emit ParentChanged(address(parent));
    }

    function setTokenAddress(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');
        require(address(token) == address(0), 'Staking: tokens already set!');
        token = _token;
        emit TokenAddressChanged(address(token));
    }

    function setTokenPerBlock(uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public virtual onlyOwner {
        if (_startBlock != startBlock) setStartBlock(_startBlock);
        if (_closeBlock != closeBlock) setCloseBlock(_closeBlock);
        setTokenPerBlock(_tokenPerBlock);
    }

    function setTokenPerBlock(uint256 _tokenPerBlock) public virtual onlyOwner {
        require(startBlock != 0, 'Staking: cannot set reward before setting start block');
        for (uint i=0; i<maxPid; i++) updatePool(i);
        tokenPerBlock = _tokenPerBlock;
        emit TokenRewardsChanged(address(token), _tokenPerBlock);
    }

    function setStartBlock(uint256 _startBlock) public virtual onlyOwner {
        require(startBlock == 0 || startBlock > block.number, 'Staking: start block already set');
        require(_startBlock > 0, 'Staking: start block needs to be higher than zero!');
        startBlock = _startBlock;
        emit StartBlockChanged(_startBlock);
    }

    function setCloseBlock(uint256 _closeBlock) public virtual onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock == 0 || closeBlock > block.number, 'Staking: close block already set');
        require(_closeBlock == 0 || _closeBlock > startBlock, 'Staking: close block needs to be higher than start one!');
        closeBlock = _closeBlock;
        emit CloseBlockChanged(_closeBlock);
    }

    function withdrawRemaining(address addr) external virtual onlyOwner {
        if (startBlock == 0 || closeBlock == 0 || block.number <= closeBlock) {
            return;
        }
        for (uint i=0; i<maxPid; i++) {
            updatePool(i);
        }

        uint256 allTokenRewarded = 0;
        uint256 allTokenReceived = 0;

        for (uint i=0; i<maxPid; i++) {
            allTokenRewarded = allTokenRewarded.add(poolInfo[i].realTokenRewarded);
            allTokenReceived = allTokenReceived.add(poolInfo[i].realTokenReceived);
        }

        uint256 unlockedAmount = 0;
        uint256 possibleAmount = token.balanceOf(address(parent));
        uint256 reservedAmount = allTokenRewarded.sub(allTokenReceived);

        // if token is the same as deposit token then deduct staked tokens as non withdrawable
        if (address(token) == address(parent.token())) {
            for (uint i=0; i<maxPid; i++) {
                reservedAmount = reservedAmount.add(getParentPoolInfo(i).tokenRealStaked);
            }
        }

        if (possibleAmount > reservedAmount) {
            unlockedAmount = possibleAmount.sub(reservedAmount);
        }
        if (unlockedAmount > 0) {
            token.safeTransferFrom(address(parent), addr, unlockedAmount);
            emit WithdrawnRemain(addr, 0, address(token), unlockedAmount);
        }
    }

    function pendingRewards(uint256 pid, address addr) external virtual view returns (uint256) {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;

        uint256 lastMintedBlock = pool.lastBlock;
        if (lastMintedBlock == 0) {
            lastMintedBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock == 0) {
            return 0;
        }
        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        uint256 poolTokenRealStaked = superPool.tokenVirtStaked;

        uint256 realTokenPerShare = pool.realTokenPerShare;
        if (lastBlock > lastMintedBlock && poolTokenRealStaked != 0) {
            uint256 tokenPerShare = superPool.tokenPerShare.sub(pool.tokenPerShare);
            realTokenPerShare = realTokenPerShare.add(tokenPerShare.mul(tokenPerBlock));
        }

        return amount.mul(realTokenPerShare).div(1e12).div(tokenParentPrecision).sub(user.rewardDebt).add(user.pendingRewards);
    }

    function update(uint256 pid, address user, uint256 amount) external virtual onlyOwner {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return;
        }
        updatePool(pid);
        updatePendingReward(pid, user);
        updateRealizeReward(pid, user, amount);
    }

    function claim(uint256 pid, address addr) external virtual onlyOwner returns (uint256) {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];

        updatePool(pid);
        updatePendingReward(pid, addr);

        uint256 claimedAmount = 0;
        if (user.pendingRewards > 0) {
            claimedAmount = transferPendingRewards(pid, addr, user.pendingRewards);
            emit WithdrawnReward(addr, pid, address(token), claimedAmount);
            user.pendingRewards = user.pendingRewards.sub(claimedAmount);
            pool.realTokenReceived = pool.realTokenReceived.add(claimedAmount);
        }

        updateRealizeReward(pid, addr);

        return claimedAmount;
    }

    function addPool(uint256 pid) internal {
        require(maxPid < 10, 'Staking: Cannot add more than 10 pools!');

        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        poolInfo.push(PoolInfo({
            lastBlock: 0,
            tokenPerShare: superPool.tokenPerShare,
            tokenRewarded: superPool.tokenRewarded,
            realTokenPerShare: 0,
            realTokenReceived: 0,
            realTokenRewarded: 0
        }));
        maxPid = maxPid.add(1);
    }

    function updatePool(uint256 pid) internal {
        if (pid >= maxPid) {
            return;
        }
        if (startBlock == 0 || block.number < startBlock) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lastBlock == 0) {
            pool.lastBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock <= pool.lastBlock) {
            return;
        }
        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        uint256 poolTokenRealStaked = superPool.tokenVirtStaked;
        if (poolTokenRealStaked == 0) {
            return;
        }

        // compute the difference between last update in vendor and last update in core staking contract
        // then multiply it by rewardPerBlock value to correctly compute reward
        uint256 multiplier = lastBlock.sub(pool.lastBlock);
        uint256 divisor = superPool.lastBlock.sub(pool.lastBlock);

        uint256 tokenRewarded = superPool.tokenRewarded.sub(pool.tokenRewarded);
        uint256 tokenPerShare = superPool.tokenPerShare.sub(pool.tokenPerShare);

        // if multiplier is different than divisor it means, that before update vendor contract has been closed, therefore
        // we need to multiply the values instead of overwtiitng as the block after close should not count here
        if (multiplier != divisor) {
            tokenRewarded = tokenRewarded.mul(multiplier).div(divisor);
            tokenPerShare = tokenPerShare.mul(multiplier).div(divisor);
        }
        pool.tokenRewarded = pool.tokenRewarded.add(tokenRewarded);
        pool.tokenPerShare = pool.tokenPerShare.add(tokenPerShare);

        pool.realTokenRewarded = pool.realTokenRewarded.add(tokenRewarded.mul(tokenPerBlock).div(tokenParentPrecision));
        pool.realTokenPerShare = pool.realTokenPerShare.add(tokenPerShare.mul(tokenPerBlock));
        pool.lastBlock = lastBlock;
    }

    function updatePendingReward(uint256 pid, address addr) internal {
        if (pid >= maxPid) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;

        uint256 reward;
        reward = amount.mul(pool.realTokenPerShare).div(1e12).div(tokenParentPrecision).sub(user.rewardDebt);
        if (reward > 0) {
            user.pendingRewards = user.pendingRewards.add(reward);
            user.rewardDebt = user.rewardDebt.add(reward);
        }
    }

    function updateRealizeReward(uint256 pid, address addr) internal {
        if (pid >= maxPid) {
            return;
        }
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;
        return updateRealizeReward(pid, addr, amount);
    }

    function updateRealizeReward(uint256 pid, address addr, uint256 amount) internal {
        if (pid >= maxPid) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        uint256 reward;
        reward = amount.mul(pool.realTokenPerShare).div(1e12).div(tokenParentPrecision);
        user.rewardDebt = reward;
    }

    function transferPendingRewards(uint256 pid, address to, uint256 amount) internal returns (uint256) {
        if (pid >= maxPid) {
            return 0;
        }
        if (amount == 0) {
            return 0;
        }
        uint256 tokenAmount = token.balanceOf(address(parent));

        // if reward token is the same as deposit token deduct its balane from withdrawable amount
        if (tokenAmount != 0 && address(token) == address(parent.token())) {
            for (uint i=0; i<maxPid && tokenAmount > 0; i++) {
                uint256 tokenRealStaked = getParentPoolInfo(i).tokenRealStaked;
                tokenAmount = (tokenRealStaked >= tokenAmount) ? 0 : tokenAmount.sub(tokenRealStaked);
            }
        }
        if (tokenAmount == 0) {
            return 0;
        }
        if (tokenAmount > amount) {
            tokenAmount = amount;
        }
        token.safeTransferFrom(address(parent), to, tokenAmount);
        return tokenAmount;
    }

    function getLastRewardBlock() internal view returns (uint256) {
        if (startBlock == 0) return 0;
        if (closeBlock != 0 && closeBlock < block.number) return closeBlock;
        return block.number;
    }

    function getParentUserInfo(uint256 pid, address addr) internal view returns (SuperUserInfo memory) {
        ( uint256 amount, uint256 rewardDebt, uint256 pending, uint256 lockedTimestamp, uint256 lockupTimestamp,
        uint256 lockupTimerange, uint256 virtAmount ) = parent.userInfo(pid, addr);
        return SuperUserInfo({
            amount: amount, rewardDebt: rewardDebt, pendingRewards: pending, lockedTimestamp: lockedTimestamp,
            lockupTimestamp: lockupTimestamp, lockupTimerange: lockupTimerange, virtAmount: virtAmount
        });
    }

    function getParentPoolInfo(uint256 pid) internal view returns (SuperPoolInfo memory) {
        ( uint256 lastBlock, uint256 tokenPerShare, uint256 tokenRealStaked, uint256 tokenVirtStaked,
        uint256 tokenRewarded, uint256 tokenTotalLimit, uint256 lockupMaxTimerange, uint256 lockupMinTimerange ) = parent.poolInfo(pid);
        return SuperPoolInfo({
            lastBlock: lastBlock, tokenPerShare: tokenPerShare, tokenRealStaked: tokenRealStaked,
            tokenVirtStaked: tokenVirtStaked, tokenRewarded: tokenRewarded, tokenTotalLimit: tokenTotalLimit,
            lockupMaxTimerange: lockupMaxTimerange, lockupMinTimerange: lockupMinTimerange
        });
    }
}