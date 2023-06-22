// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IBurnable.sol";
import "./interfaces/IFarmManager.sol";

// Farm distributes the ERC20 rewards based on staked LP to each user.
contract Farm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

        // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastClaimTime;
        uint256 withdrawTime;
        
        // We do some fancy math here. Basically, any point in time, the amount of ERC20s
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken;         // Address of staking token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
        uint256 supply;             // changes with unstakes.
        bool    isLP;               // if the staking token is an LP token.
        bool    isBurnable;         // if the staking token is burnable
    }

    // Address of the ERC20 Token contract.
    IERC20 public erc20;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut;
    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock;
    // Manager interface to get globals for all farms.
    IFarmManager public manager;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when farming starts.
    uint256 public startBlock;
    // Seconds per epoch (1 day)
    uint256 public constant SECS_EPOCH = 86400;

    // events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid);
    event Claim(address indexed user, uint256 indexed pid);
    event Unstake(address indexed user, uint256 indexed pid);
    event Initialize(IERC20 erc20, uint256 rewardPerBlock, uint256 startBlock, address manager);

    constructor(IERC20 _erc20, uint256 _rewardPerBlock, uint256 _startBlock, address _manager) public {
        erc20 = _erc20;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        manager = IFarmManager(_manager);
        emit Initialize(_erc20, _rewardPerBlock, _startBlock, _manager);
    }

    // Fund the farm, increase the end block.
    function fund(address _funder, uint256 _amount) external {
        require(msg.sender == address(manager), "fund: sender is not manager");
        erc20.safeTransferFrom(_funder, address(this), _amount);
    }

    // Update the given pool's ERC20 allocation point. Can only be called by the manager.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external {
        require(msg.sender == address(manager), "set: sender is not manager");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Add a new staking token to the pool. Can only be called by the manager.
    function add(uint256 _allocPoint, IERC20 _stakingToken, bool _isLP, bool _isBurnable, bool _withUpdate) external {
        require(msg.sender == address(manager), "fund: sender is not manager");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            stakingToken: _stakingToken,
            supply: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accERC20PerShare: 0,
            isLP: _isLP,
            isBurnable: _isBurnable
        }));
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
        uint256 lastBlock = block.number;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        if (pool.supply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
        uint256 erc20Reward = nrOfBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accERC20PerShare = pool.accERC20PerShare.add(erc20Reward.mul(1e36).div(pool.supply));
        pool.lastRewardBlock = block.number;
    }

    // move LP tokens from one farm to another. only callable by Manager.
    function move(uint256 _pid, address _mover) external {
        require(msg.sender == address(manager), "move: sender is not manager");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_mover];
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
        erc20Transfer(_mover, pendingAmount);
        pool.supply = pool.supply.sub(user.amount);
        pool.stakingToken.safeTransfer(address(manager), user.amount);
        user.amount = 0;
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        emit Withdraw(msg.sender, _pid);
    }

    // Deposit LP tokens to Farm for ERC20 allocation.
    // can come from manager or user address directly.
    // In the case the call is coming from the manager, msg.sender is the manager.
    function deposit(uint256 _pid, address _depositor, uint256 _amount) external {
        require(manager.getPaused()==false, "deposit: farm paused");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositor];
        require(user.withdrawTime == 0, "deposit: user is unstaking");

        // If we're not called by the farm manager, then we must ensure that the caller is the depositor.
        // This way we avoid the case where someone else commits the deposit, after the depositor
        // granted allowance to the farm.
        if(msg.sender != address(manager)) {
            require(msg.sender == _depositor, "deposit: the caller must be the depositor");
        }

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
            erc20Transfer(_depositor, pendingAmount);
        }

        // We tranfer from the msg.sender, because in the case when we're called by the farm manager (change pool scenario)
        // it's the FM who owns the tokens, not the depositor (who in this case is the user who changes pools).
        pool.stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        pool.supply = pool.supply.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        emit Deposit(_depositor, _pid, _amount);
    }

    // Distribute rewards and start unstake period.
    function withdraw(uint256 _pid) external {
        require(manager.getPaused()==false, "withdraw: farm paused");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "withdraw: amount must be greater than 0");
        require(user.withdrawTime == 0, "withdraw: user is unstaking");
        updatePool(_pid);

        // transfer any rewards due
        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
        erc20Transfer(msg.sender, pendingAmount);
        pool.supply = pool.supply.sub(user.amount);
        user.rewardDebt = 0;
        user.withdrawTime = block.timestamp;
        emit Withdraw(msg.sender, _pid);
    }

    // unstake LP tokens from Farm. if done within "unstakeEpochs" days, apply burn.
    function unstake(uint256 _pid) external {
        require(manager.getPaused()==false, "unstake: farm paused");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.withdrawTime > 0, "unstake: user is not unstaking");
        updatePool(_pid);
        //apply burn fee if unstaking before unstake epochs.
        uint256 unstakeEpochs = manager.getUnstakeEpochs();
        uint256 burnRate = manager.getBurnRate();
        address redistributor = manager.getRedistributor();
        if((user.withdrawTime.add(SECS_EPOCH.mul(unstakeEpochs)) > block.timestamp) && burnRate > 0){
            uint penalty = user.amount.mul(burnRate).div(1000);
            user.amount = user.amount.sub(penalty);
            // if the staking address is an LP, send 50% of penalty to redistributor, and 50% to lp lock address.
            if(pool.isLP){
                uint256 redistributorPenalty = penalty.div(2);
                pool.stakingToken.safeTransfer(redistributor, redistributorPenalty);
                pool.stakingToken.safeTransfer(manager.getLpLock(), penalty.sub(redistributorPenalty));
            }else {
                // for normal ERC20 tokens, a portion (50% by default) of the penalty is sent to the redistributor address
                uint256 burnRatio = manager.getBurnRatio();
                uint256 burnAmount = penalty.mul(burnRatio).div(1000);
                pool.stakingToken.safeTransfer(redistributor, penalty.sub(burnAmount));
                if(pool.isBurnable){
                    //if the staking token is burnable, the second portion (50% by default) is burned
                    IBurnable(address(pool.stakingToken)).burn(burnAmount);
                }else{
                    //if the staking token is not burnable, the second portion (50% by default) is sent to burn valley
                    pool.stakingToken.safeTransfer(manager.getBurnValley(), burnAmount);
                }
            }
        }
        uint userAmount = user.amount;
        // allows user to stake again.
        user.withdrawTime = 0;
        user.amount = 0;
        pool.stakingToken.safeTransfer(address(msg.sender), userAmount);
        emit Unstake(msg.sender, _pid);
    }

    // claim LP tokens from Farm.
    function claim(uint256 _pid) external {
        require(manager.getPaused() == false, "claim: farm paused");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "claim: amount is equal to 0");
        require(user.withdrawTime == 0, "claim: user is unstaking");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
        erc20Transfer(msg.sender, pendingAmount);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        user.lastClaimTime = block.timestamp;
        emit Claim(msg.sender, _pid);
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function erc20Transfer(address _to, uint256 _amount) internal {
        erc20.transfer(_to, _amount);
        paidOut += _amount;
    }

    // emergency withdraw rewards. only owner. EMERGENCY ONLY.
    function emergencyWithdrawRewards(address _receiver) external {
        require(msg.sender == address(manager), "emergencyWithdrawRewards: sender is not manager");
        uint balance = erc20.balanceOf(address(this));
        erc20.safeTransfer(_receiver, balance);
    }
}