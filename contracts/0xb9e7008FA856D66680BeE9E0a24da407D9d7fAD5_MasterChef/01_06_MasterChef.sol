// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SafeTransferLib,ERC20} from "@solmate/utils/SafeTransferLib.sol"; 
import "@solmate/auth/Owned.sol";

import "./interfaces/IMint.sol"; 
import "./interfaces/IStake2.sol";

// MasterChef is the master of ERC20 token. He can make rewardToken and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once  rewardToken is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Owned(msg.sender) {
    uint256 constant _PRECISION = 1e12;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 index; // index is the cumulative value of each share's reward.
            // See explanation below.
            //
            // We do some fancy math here. Basically, any point in time, the amount of Rewards
            // entitled to a user but is pending to be distributed is:
            //
            //   pending reward = user.amount * ( pool.accRewardPerShareIndex -  user.index)
            //
            // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
            //   1. The pool's `accRewardPerShareIndex` (and `lastRewardTime`) gets updated.
            //   2. User receives the pending reward sent to his/her address.
            //   3. User's `amount` gets updated.
            //   4. User's `index` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardTime; // Last block time that Rewards distribution occurs.
        uint256 accRewardPerShareIndex; // Accumulated Rewards per share, times 1e12. See below.
        IStake2 stake2; // Stake2 contract address, will be called when deposit/withdraw.
    }
    // The block number when Reward mining starts.

    uint256 public immutable startTime;
    // The Reward TOKEN!
    IMint public rewardToken;
    // Reward tokens created per second.
    uint256 public rewardPerSecond;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    constructor(uint256 rewardPerSecond_, uint256 start_) {
        rewardPerSecond = rewardPerSecond_;
        startTime = start_;
    }

    // Deposit LP tokens to MasterChef for Reward allocation.
    function deposit(uint256 pid, uint256 amount) public payable {
        if (amount == 0) revert DEPOSIT_AMOUNT_ZERO();

        _updateReward(pid, msg.sender);

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        _transferTokenIn(pool.lpToken, amount);
        user.amount += amount;

        // call stake2 contract when deposit
        if (address(pool.stake2) != address(0)) pool.stake2.onDeposited(msg.sender, amount);

        emit Deposit(msg.sender, pid, amount, user.index);
    }

    // Deposit LP tokens to MasterChef for Reward allocation.
    // Deposit with permit for approval.
    function depositWithPermit(uint256 pid, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        ERC20(poolInfo[pid].lpToken).permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(pid, amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 pid, uint256 amount) external {
        if (amount == 0) revert WITHDRAW_AMOUNT_ZERO();

        _updateReward(pid, msg.sender);

        UserInfo storage user = userInfo[pid][msg.sender];
        if (user.amount < amount) revert WITHDRAW_AMOUNT_TOO_LARGE();

        PoolInfo storage pool = poolInfo[pid];
        unchecked {
            user.amount -= amount;
        }
        _transferTokenOut(pool.lpToken, amount);

        // call stake2 contract when withdraw
        if (address(pool.stake2) != address(0)) pool.stake2.onWithdrawn(msg.sender, amount);

        emit Withdraw(msg.sender, pid, amount, user.index);
    }

    function claim(uint256 pid) external {
        _updateReward(pid, msg.sender);
    }

    function claimFor(uint256 pid, address user) external {
        _updateReward(pid, user);
    }

    function batchClaim(uint256[] calldata pids) external {
        for (uint256 i = 0; i < pids.length; i++) {
            _updateReward(pids[i], msg.sender);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.index = 0;
        _transferTokenOut(address(pool.lpToken), amount);
        emit EmergencyWithdraw(msg.sender, pid, amount);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        pool.accRewardPerShareIndex = _currentRewardPerShare(pid);
        pool.lastRewardTime = block.timestamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return reward multiplier over the given _from to _to block.
    // View function to see pending Rewards on frontend.
    function pendingReward(uint256 pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[pid][_user];
        // ignore big amount
        unchecked {
            return user.amount * (_currentRewardPerShare(pid) - user.index) / _PRECISION;
        }
    }

    //********************************************************
    //****************** ADMIN FUNCTIONS *********************
    //********************************************************

    function setRewardPerSecond(uint256 rewardPerSecond_) external onlyOwner {
        massUpdatePools();
        rewardPerSecond = rewardPerSecond_;
        emit RewardPerSecondUpdated(rewardPerSecond);
    }

    // Add a new lpToken to the pool. Can only be called by the owner.
    // XXX DO NOT add the same lpToken token more than once. Rewards will be messed up if you do.
    function add(uint256 allocPoint, address lpToken, IStake2 stake2, bool withUpdate) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        unchecked {
            totalAllocPoint += allocPoint;
        }
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken,
                allocPoint: allocPoint,
                lastRewardTime: lastRewardTime,
                accRewardPerShareIndex: 0,
                stake2: stake2
            })
        );

        emit PoolUpdated(poolInfo.length - 1, allocPoint);
    }

    // Update the given pool's Reward allocation point. Can only be called by the owner.
    function set(uint256 pid, uint256 allocPoint, bool withUpdate) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[pid].allocPoint;
        poolInfo[pid].allocPoint = allocPoint;

        unchecked {
            totalAllocPoint = totalAllocPoint - prevAllocPoint + allocPoint;
        }

        emit PoolUpdated(pid, allocPoint);
    }

    function setRewardToken(IMint newToken) external onlyOwner {
        rewardToken = newToken;
        emit RewardTokenUpdated(address(newToken));
    }

    //********************************************************
    //****************** INTERNAL FUNCTIONS ******************
    //********************************************************

    function _currentRewardPerShare(uint256 pid) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        uint256 accRewardPerShareIndex = pool.accRewardPerShareIndex;
        uint256 lpSupply =
            pool.lpToken == address(0) ? address(this).balance : ERC20(pool.lpToken).balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply > 0) {
            // We can ignore the overflow issue, which will not happen during the continuous operation of the protocol.
            // (block.timestamp - pool.lastRewardTime)  will not cause an overflow.
            // (rewardPerSecond * pool.allocPoint) will not cause an overflow.

            uint256 index;
            unchecked {
                uint256 rewards =
                    (block.timestamp - pool.lastRewardTime) * rewardPerSecond * pool.allocPoint / totalAllocPoint;

                index = rewards * _PRECISION / lpSupply;
            }
            accRewardPerShareIndex += index;
        }
        return accRewardPerShareIndex;
    }

    function _updateReward(uint256 pid, address account) private {
        // Rewards should only be sent to a staker after the pool state has been updated.
        updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];

        if (user.amount > 0) {
            uint256 pending = user.amount * (pool.accRewardPerShareIndex - user.index) / _PRECISION;
            // update reward index before transfer for reentrancy.
            user.index = pool.accRewardPerShareIndex;
            if (pending > 0) rewardToken.mint(account, pending);
        } else {
            user.index = pool.accRewardPerShareIndex;
        }
    }

    function _transferTokenIn(address token, uint256 amount) private {
        if (token == address(0)) {
            if (amount != msg.value) revert AMOUNT_IS_NOT_ENOUGH();
        } else {
            SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        }
    }

    function _transferTokenOut(address token, uint256 amount) private {
        if (amount == 0) return;
        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        } else {
            SafeTransferLib.safeTransfer(ERC20(token), msg.sender, amount);
        }
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 index);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 index);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPerSecondUpdated(uint256 newRewards);
    event PoolUpdated(uint256 pid, uint256 allocPoint);
    event RewardTokenUpdated(address newToken);

    error AMOUNT_IS_NOT_ENOUGH();
    error DEPOSIT_AMOUNT_ZERO();
    error WITHDRAW_AMOUNT_TOO_LARGE();
    error WITHDRAW_AMOUNT_ZERO();
}