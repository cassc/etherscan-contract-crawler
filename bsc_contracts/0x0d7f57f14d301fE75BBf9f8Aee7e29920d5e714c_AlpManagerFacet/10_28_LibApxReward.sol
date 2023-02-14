// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IApxReward} from "../interfaces/IApxReward.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibApxReward {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 constant APX_REWARD_POSITION = keccak256("apollox.apx.reward.storage");

    /* ========== STATE VARIABLES ========== */
    struct ApxRewardStorage {
        IERC20 rewardToken;
        // Mining start block
        uint256 startBlock;
        // Info of each pool.
        IApxReward.ApxPoolInfo poolInfo;
        // Info of each user that stakes LP tokens.
        mapping(address => IApxReward.ApxUserInfo) userInfo;
    }

    event ClaimApxReward(address indexed user, uint256 reward);
    event AddReserves(address indexed contributor, uint256 amount);

    function apxRewardStorage() internal pure returns (ApxRewardStorage storage ars) {
        bytes32 position = APX_REWARD_POSITION;
        assembly {
            ars.slot := position
        }
    }

    function initialize(address _rewardsToken, uint256 _apxPerBlock, uint256 _startBlock) internal {
        ApxRewardStorage storage st = apxRewardStorage();
        require(address(st.rewardToken) == address(0), "Already initialized!");
        st.rewardToken = IERC20(_rewardsToken);
        st.startBlock = _startBlock;
        // staking pool
        st.poolInfo = IApxReward.ApxPoolInfo({
            totalStaked : 0,
            apxPerBlock : _apxPerBlock,
            lastRewardBlock : _startBlock,
            accAPXPerShare : 0,
            totalReward : 0,
            reserves: 0
        });
    }

    /* ========== VIEWS ========== */

    function apxPoolInfo() internal view returns (IApxReward.ApxPoolInfo memory poolInfo) {
        ApxRewardStorage storage ars = apxRewardStorage();
        IApxReward.ApxPoolInfo storage pool = ars.poolInfo;

        poolInfo.totalStaked = pool.totalStaked;
        poolInfo.apxPerBlock = pool.apxPerBlock;
        poolInfo.lastRewardBlock = pool.lastRewardBlock;
        poolInfo.accAPXPerShare = pool.accAPXPerShare;

        uint256 apxReward;
        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0) {
            uint256 blockGap = block.number.sub(pool.lastRewardBlock);
            apxReward = blockGap.mul(pool.apxPerBlock);
        }
        poolInfo.totalReward = pool.totalReward.add(apxReward);
        poolInfo.reserves = pool.reserves;
    }

    // View function to see pending APXs on frontend.
    function pendingApx(address _user) internal view returns (uint256) {
        ApxRewardStorage storage st = apxRewardStorage();
        IApxReward.ApxPoolInfo storage pool = st.poolInfo;
        IApxReward.ApxUserInfo storage user = st.userInfo[_user];
        uint256 accApxPerShare = pool.accAPXPerShare;
        uint256 lpSupply = pool.totalStaked;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockGap = block.number.sub(pool.lastRewardBlock);
            uint256 apxReward = blockGap.mul(pool.apxPerBlock);
            accApxPerShare = accApxPerShare.add(apxReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accApxPerShare).div(1e12).sub(user.rewardDebt).add(user.pendingReward);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 _amount) internal {
        ApxRewardStorage storage st = apxRewardStorage();
        require(_amount > 0, 'Invalid amount');
        require(block.number >= st.startBlock, "Mining not started yet");
        IApxReward.ApxPoolInfo storage pool = st.poolInfo;
        IApxReward.ApxUserInfo storage user = st.userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accAPXPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                user.pendingReward = user.pendingReward.add(pending);
            }
        }

        pool.totalStaked = pool.totalStaked.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accAPXPerShare).div(1e12);
    }

    function unStake(uint256 _amount) internal {
        ApxRewardStorage storage st = apxRewardStorage();

        IApxReward.ApxPoolInfo storage pool = st.poolInfo;
        IApxReward.ApxUserInfo storage user = st.userInfo[msg.sender];

        require(_amount > 0, "Invalid withdraw amount");
        require(user.amount >= _amount, "Insufficient balance");
        updatePool();
        uint256 pending = user.amount.mul(pool.accAPXPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            user.pendingReward = user.pendingReward.add(pending);
        }

        user.amount = user.amount.sub(_amount);
        pool.totalStaked = pool.totalStaked.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accAPXPerShare).div(1e12);
    }

    function claimApxReward(address account) internal {
        ApxRewardStorage storage st = apxRewardStorage();
        IApxReward.ApxPoolInfo storage pool = st.poolInfo;
        IApxReward.ApxUserInfo storage user = st.userInfo[account];

        updatePool();
        uint256 pending = user.amount.mul(pool.accAPXPerShare).div(1e12).sub(user.rewardDebt).add(user.pendingReward);
        if (pending > 0) {
            user.pendingReward = 0;
            user.rewardDebt = user.amount.mul(pool.accAPXPerShare).div(1e12);
            require(pool.reserves >= pending, "LibApxReward: APX reserves shortage");
            pool.reserves -= pending;
            st.rewardToken.safeTransfer(account, pending);
            emit ClaimApxReward(account, pending);
        }
    }

    function addReserves(uint256 amount) internal {
        ApxRewardStorage storage ars = apxRewardStorage();
        IApxReward.ApxPoolInfo storage pool = ars.poolInfo;
        ars.rewardToken.transferFrom(msg.sender, address(this), amount);
        pool.reserves += amount;
        emit AddReserves(msg.sender, amount);
    }

    //Todo test apxPerBlock updated
    function updateApxPerBlock(uint256 _apxPerBlock) internal {
        ApxRewardStorage storage st = apxRewardStorage();
        require(_apxPerBlock >= 0, "apxPerBlock greater than 0");
        updatePool();
        st.poolInfo.apxPerBlock = _apxPerBlock;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() internal {
        ApxRewardStorage storage st = apxRewardStorage();
        IApxReward.ApxPoolInfo storage pool = st.poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockGap = block.number.sub(pool.lastRewardBlock);
        uint256 apxReward = blockGap.mul(pool.apxPerBlock);
        pool.totalReward = pool.totalReward.add(apxReward);
        pool.accAPXPerShare = pool.accAPXPerShare.add(apxReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
}