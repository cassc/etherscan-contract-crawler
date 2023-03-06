pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DoughPool is Ownable {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DOUGHs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDoughPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDoughPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;            // Address of LP token contract.
        uint256 lastRewardBlock;   // Last block number that DOUGHs distribution occurs.
        uint256 accDoughPerShare;  // Accumulated DOUGHs per share, times 1e12. See below.
        uint256 doughPerBlock;     // Block reward per pool
        uint256 poolBonusEndBlock; // Bonus end block
        uint256 bonusMultiplier;   // Bonus multiplier (Only is enabled if within the bonusEndBlock)
    }

    function addDough(uint256 _amount) public onlyOwner {
        dough.transferFrom(msg.sender, address(this), _amount);
    }

    // The DOUGH TOKEN!
    IERC20 public dough;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // The block number when DOUGH mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address user, uint256 _amount, uint256 _pid);
    event PoolCreated(IERC20 _lpToken, bool _withUpdate, uint256 _doughPerBlock);

    constructor(
        IERC20 _dough,
        uint256 _startBlock
    ) {
        dough = _dough;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _lpToken, bool _withUpdate, uint256 _doughPerBlock) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: lastRewardBlock,
            accDoughPerShare: 0,
            doughPerBlock: _doughPerBlock,
            poolBonusEndBlock: block.number,
            bonusMultiplier: 1
        }));
        emit PoolCreated(_lpToken, _withUpdate, _doughPerBlock);
    }

    // Update the given pool's DOUGH block reward. Can only be called by the owner.
    function setBlockReward(uint256 _pid, uint256 _doughPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_pid].doughPerBlock = _doughPerBlock;
    }

    // Update the given pool's bonus block end. Can only be called by the owner.
    function setMultiplier(uint256 _pid, uint256 _poolBonusEndBlock, uint256 _bonusMultiplier, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_pid].poolBonusEndBlock = _poolBonusEndBlock;
        poolInfo[_pid].bonusMultiplier = _bonusMultiplier;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 _pid) public view returns (uint256) {
        if (_to <= poolInfo[_pid].poolBonusEndBlock) {
            return _to.sub(_from).mul(poolInfo[_pid].bonusMultiplier);
        } else if (_from >= poolInfo[_pid].poolBonusEndBlock) {
            return _to.sub(_from);
        } else {
            return poolInfo[_pid].poolBonusEndBlock.sub(_from).mul(poolInfo[_pid].bonusMultiplier).add(
                _to.sub(poolInfo[_pid].poolBonusEndBlock)
            );
        }
    }

    // View function to see pending DOUGHs on frontend.
    function pendingDough(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDoughPerShare = pool.accDoughPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, _pid);
            uint256 doughReward = multiplier.mul(pool.doughPerBlock);
            accDoughPerShare = accDoughPerShare.add(doughReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accDoughPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Does not need to be public, but making it public for debugging purposes.
    function forRewardDebt(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDoughPerShare = pool.accDoughPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, _pid);
            uint256 doughReward = multiplier.mul(pool.doughPerBlock);
            accDoughPerShare = accDoughPerShare.add(doughReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accDoughPerShare).div(1e12);
    }

    function harvest(uint256 _pid, address _user) internal {
        UserInfo storage user = userInfo[_pid][_user];

        if (user.amount > 0) {
            uint256 _pendingDough = pendingDough(_pid, _user);
            // uint256 pending = _pendingDough.sub(user.rewardDebt);
            // user.rewardDebt = forRewardDebt(_pid, _user); /* I don't think that we'll need this anymore */
            safeDoughTransfer(msg.sender, _pendingDough);
            emit Harvest(_user, _pendingDough, _pid);
        }
    }

    function setRewardDebt(uint256 _pid, address _user) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        user.rewardDebt = user.amount.mul(pool.accDoughPerShare).div(1e12);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
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
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, _pid);
        uint256 doughReward = multiplier.mul(pool.doughPerBlock);
        pool.accDoughPerShare = pool.accDoughPerShare.add(doughReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function getBalance(uint256 _pid, address _user) public view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    // Deposit LP tokens to DoughFarm for DOUGH allocation
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        harvest(_pid, msg.sender);
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        setRewardDebt(_pid, msg.sender); // SET REWARD DEBT.
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from DoughFarm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        harvest(_pid, msg.sender);
        pool.lpToken.transfer(address(msg.sender), _amount);
        user.amount = user.amount.sub(_amount);
        setRewardDebt(_pid, msg.sender); // SET REWARD DEBT.
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0; // Set user balance to zero
        user.rewardDebt = forRewardDebt(_pid, msg.sender); // Make sure user doesn't get any free tokens
    }

    // Safe dough transfer function, just in case if rounding error causes pool to not have enough DOUGHs.
    function safeDoughTransfer(address _to, uint256 _amount) internal {
        uint256 doughBal = dough.balanceOf(address(this));
        if (_amount > doughBal) {
            dough.transfer(_to, doughBal);
        } else {
            dough.transfer(_to, _amount);
        }
    }
}