pragma solidity 0.6.12;

import "./lib/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./SwaposToken.sol";

// import "@nomiclabs/buidler/console.sol";

interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of SWP. He can make SWP and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SWP is sufficiently
// distributed and the community can show to govern itself.R
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SWPs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSWPPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSWPPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SWPs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SWPs distribution occurs.
        uint256 accSWPPerShare; // Accumulated SWPs per share, times 1e12. See below.
    }

    // The SWP TOKEN!
    SwpToken public SWP;

    uint256 public devPercent;
    address public devaddr;
    uint256 public blockWithdrawDev;
    uint256 public depositedSwp;

    // SWP tokens created per block.
    uint256 public SWPPerBlock;
    // Bonus muliplier for early SWP makers.
    uint256 public BONUS_MULTIPLIER;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when SWP mining starts.
    uint256 public startBlock;

    event Earned(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function initialize(
        SwpToken _SWP,
        address _devaddr,
        uint256 _SWPPerBlock,
        uint256 _startBlock
    ) public initializer {
        SWP = _SWP;
        devaddr = _devaddr;
        SWPPerBlock = _SWPPerBlock;
        startBlock = _startBlock;
        blockWithdrawDev = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _SWP,
            allocPoint: 3000,
            lastRewardBlock: startBlock,
            accSWPPerShare: 0
        }));

        totalAllocPoint = 3000;
        BONUS_MULTIPLIER = 1;

        __Ownable_init();
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getDevTokens() public{
        require(blockWithdrawDev < block.number, 'bad block');
        uint256 multiplier = getMultiplier(blockWithdrawDev, block.number);
        uint256 SWPReward = multiplier.mul(SWPPerBlock);
        SWP.mint(devaddr, SWPReward.mul(145).div(1000));
        blockWithdrawDev = block.number;
    }

    function newDevAddress(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function newSWPPerBlock(uint256 newAmount) public onlyOwner {
        SWPPerBlock = newAmount;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add( uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSWPPerShare: 0
            })
        );
    }

    // Update the given pool's SWP allocation point. Can only be called by the owner.
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending SWPs on frontend.
    function pendingSWP(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSWPPerShare = pool.accSWPPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedSwp;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 SWPReward = multiplier.mul(SWPPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(855).div(1000);
            accSWPPerShare = accSWPPerShare.add(SWPReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSWPPerShare).div(1e12).sub(user.rewardDebt);
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
        if (_pid == 0){
            lpSupply = depositedSwp;
        }
        if (lpSupply <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 SWPReward = multiplier.mul(SWPPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(855).div(1000);
        SWP.mint(address(this), SWPReward);
        pool.accSWPPerShare = pool.accSWPPerShare.add(SWPReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SWP allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, 'deposit SWP by staking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSWPPerShare).div(1e12).sub(user.rewardDebt);
            safeSWPTransfer(msg.sender, pending);
            emit Earned(msg.sender, _pid, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSWPPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, 'withdraw SWP by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSWPPerShare).div(1e12).sub(user.rewardDebt);
        safeSWPTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSWPPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        emit Earned(msg.sender, _pid, pending);
    }

    // Stake SWP tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSWPPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSWPTransfer(msg.sender, pending);
                emit Earned(msg.sender, 0, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            depositedSwp = depositedSwp.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSWPPerShare).div(1e12);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw SWP tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accSWPPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeSWPTransfer(msg.sender, pending);
            emit Earned(msg.sender, 0, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            depositedSwp = depositedSwp.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSWPPerShare).div(1e12);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        if (_pid == 0){
            depositedSwp = depositedSwp.sub(user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe SWP transfer function, just in case if rounding error causes pool to not have enough SWPs.
    function safeSWPTransfer(address _to, uint256 _amount) internal {
        uint256 SWPBal = SWP.balanceOf(address(this));
        if (_amount > SWPBal) {
            SWP.transfer(_to, SWPBal);
        } else {
            SWP.transfer(_to, _amount);
        }
    }
}