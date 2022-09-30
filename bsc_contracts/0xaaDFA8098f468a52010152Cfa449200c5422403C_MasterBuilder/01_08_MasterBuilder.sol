// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MasterBuilder is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DexTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDexTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDexTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. DexTokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that DexTokens distribution occurs.
        uint256 accDexTokenPerShare; // Accumulated DexTokens per share, times 1e12. See below.
    }

    // The DEX Token!
    IERC20 public dexToken;
    // The Reward TOKEN!
    IERC20 public rewardToken;
    // Dev address.
    address public feeAddr;
    uint256 public feePerc = 0;
    // DexToken tokens created per block.
    uint256 public dexTokenPerBlock;
    // Bonus muliplier for early dexToken makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when DexToken mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _dexToken,
        IERC20 _rewardToken,
        address _feeAddr,
        uint256 _dexTokenPerBlock,
        uint256 _startBlock
    ) public {
        dexToken = _dexToken;
        rewardToken = _rewardToken;
        feeAddr = _feeAddr;
        dexTokenPerBlock = _dexTokenPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(
            PoolInfo({
                lpToken: _dexToken,
                allocPoint: 1000,
                lastRewardBlock: startBlock,
                accDexTokenPerShare: 0
            })
        );

        totalAllocPoint = 1000;
    }

    function updateDexTokenPerBlock(uint256 _dexTokenPerBlock)
        public
        onlyOwner
    {
        dexTokenPerBlock = _dexTokenPerBlock;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accDexTokenPerShare: 0
            })
        );
        updateStakingPool();
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 dexTokenReward = multiplier
            .mul(dexTokenPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        pool.accDexTokenPerShare = pool.accDexTokenPerShare.add(
            dexTokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(
                points
            );
            poolInfo[0].allocPoint = points;
        }
    }

    // Update the given pool's DexToken allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            updateStakingPool();
        }
    }

    // View function to see pending DexTokens on frontend.
    function pendingDexToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDexTokenPerShare = pool.accDexTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 dexTokenReward = multiplier
                .mul(dexTokenPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accDexTokenPerShare = accDexTokenPerShare.add(
                dexTokenReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accDexTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Deposit LP tokens to MasterBuilder for DexToken allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(_pid != 0, "deposit DexToken by staking");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accDexTokenPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeDexTokenTransfer(msg.sender, pending);
            }
        }
        uint256 fAmount = _amount.mul(feePerc).div(10000);
        uint256 rAmount = _amount.sub(fAmount);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                feeAddr,
                fAmount
            );
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                rAmount
            );
            user.amount = user.amount.add(rAmount);
        }
        user.rewardDebt = user.amount.mul(pool.accDexTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, rAmount);
    }

    // Withdraw LP tokens from MasterBuilder.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_pid != 0, "withdraw DexToken by unstaking");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user
            .amount
            .mul(pool.accDexTokenPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        if (pending > 0) {
            safeDexTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accDexTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake DexToken tokens to MasterBuilder
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accDexTokenPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeDexTokenTransfer(msg.sender, pending);
            }
        }
        uint256 fAmount = _amount.mul(feePerc).div(10000);
        uint256 rAmount = _amount.sub(fAmount);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                feeAddr,
                fAmount
            );
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                rAmount
            );
            user.amount = user.amount.add(rAmount);
        }
        user.rewardDebt = user.amount.mul(pool.accDexTokenPerShare).div(1e12);

        emit Deposit(msg.sender, 0, rAmount);
    }

    // Withdraw DexToken tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user
            .amount
            .mul(pool.accDexTokenPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        if (pending > 0) {
            safeDexTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accDexTokenPerShare).div(1e12);

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Safe dexToken transfer function, just in case if rounding error causes pool to not have enough DexTokens.
    function safeDexTokenTransfer(address _to, uint256 _amount) internal {
        rewardToken.safeTransfer(_to, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function setfeePerc(uint256 _feePerc) public onlyOwner {
        feePerc = _feePerc;
    }
}