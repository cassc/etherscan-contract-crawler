// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IGDES is IERC20 {
    function mint(address _to, uint256 _amount) external;
}

// Copied and modified from MasterChef to suit DeSpace's unique needs
contract DeSwapFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IGDES;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of gDES
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGDESPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGDESPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract or DES address (one pool will take DES)
        uint256 allocPoint; // How many allocation points assigned to this pool. gDESs to distribute per block.
        uint256 lastRewardBlock; // Last block number that gDESs distribution occurs.
        uint256 accGDESPerShare; // Accumulated gDES per share, times 1e36.
    }

    // Address of the gDES Token contract.
    IGDES public gDES;
    // The total amount of gDES that's paid out as reward.
    uint256 public gDESPaidOut = 0;
    // gDES tokens rewarded per block.
    uint256 public gDESPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when farming starts.
    uint256 public startBlock;
    // The block number when farming ends.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event NewFarm(IERC20 indexed _lpToken, uint256 allocPoint);
    event NewUpdate(uint256 indexed pid, uint256 allocPoint);

    constructor(
        IGDES _gDES,
        uint256 _gDESPerBlock,
        uint256 _startBlock,
        uint256 _blocksToLastFor
    ) public {
        gDES = _gDES;
        gDESPerBlock = _gDESPerBlock;
        startBlock = _startBlock;
        endBlock = _startBlock.add(_blocksToLastFor);
    }

    // Number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external onlyOwner {
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
                accGDESPerShare: 0
            })
        );
        emit NewFarm(_lpToken, _allocPoint);
    }

    // Update the given pool's gDES allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        emit NewUpdate(_pid, _allocPoint);
    }

    // View function to see deposited LP or DES for a user.
    function deposited(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending gDESs for a user.
    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accGDESPerShare = pool.accGDESPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

        if (
            lastBlock > pool.lastRewardBlock &&
            block.number > pool.lastRewardBlock &&
            lpSupply != 0
        ) {
            uint256 noOfBlocks = lastBlock.sub(pool.lastRewardBlock);
            uint256 gDESReward = noOfBlocks
                .mul(gDESPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accGDESPerShare = accGDESPerShare.add(
                gDESReward.mul(1e36).div(lpSupply)
            );
        }

        return user.amount.mul(accGDESPerShare).div(1e36).sub(user.rewardDebt);
    }

    // View function for total reward the farm has yet to pay out.
    function totalPending() external view returns (uint256) {
        if (block.number <= startBlock) {
            return 0;
        }

        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        return gDESPerBlock.mul(lastBlock - startBlock).sub(gDESPaidOut);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 noOfBlocks = lastBlock.sub(pool.lastRewardBlock);
        uint256 gDESReward = noOfBlocks
            .mul(gDESPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        pool.accGDESPerShare = pool.accGDESPerShare.add(
            gDESReward.mul(1e36).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens or DES to Farm for gDES allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user
                .amount
                .mul(pool.accGDESPerShare)
                .div(1e36)
                .sub(user.rewardDebt);
            gDESTransfer(msg.sender, pendingAmount);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accGDESPerShare).div(1e36);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens or DES from Farm.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            "withdraw: can't withdraw more than deposit"
        );
        updatePool(_pid);
        uint256 pendingAmount = user
            .amount
            .mul(pool.accGDESPerShare)
            .div(1e36)
            .sub(user.rewardDebt);
        gDESTransfer(msg.sender, pendingAmount);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGDESPerShare).div(1e36);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Transfer gDES and update the required gDES to payout all rewards
    function gDESTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            gDES.mint(_to, _amount);
            gDESPaidOut += _amount;
        }
    }
}