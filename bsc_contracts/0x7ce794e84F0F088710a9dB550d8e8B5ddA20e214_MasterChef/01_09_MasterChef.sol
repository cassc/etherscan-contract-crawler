// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import './libraries/SafeMath.sol';
import './interfaces/IBEP20.sol';
import './token/SafeBEP20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import "./token/FishToken.sol";

interface IRewardVault {
    function transfer(address token, address to, uint256 amount) external;
}

interface IAnycallV6Proxy {
    function executor() external view returns (address);
}

interface IAnycallExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}

// import "@nomiclabs/buidler/console.sol";

// MasterChef is the master of Cake. He can make Cake and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlockTime;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    // The FISH TOKEN!
    FishToken public cake;
    // CAKE tokens created per block.
    uint256 public cakePerSecond;
    // Bonus muliplier for early cake makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Allocation ratio for pool 0
    uint8 public allocRatio = 2;
    bool public singlePoolEnabled = false;

    // The block number when CAKE mining starts.
    uint256 public startTime = type(uint256).max;

    address public rewardVault;
    address public srcDistributor; // SidechainDistributor on arbitrum

    address constant anyCallAddress = 0xC10Ef9F491C9B59f936957026020C321651ac078; // Same address on all chains

    mapping (address => bool) public lpTokenAdded;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        FishToken _cake,
        address _rewardVault
    ) {
        cake = _cake;
        rewardVault = _rewardVault;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _cake,
            allocPoint: singlePoolEnabled ? 1000 : 0,
            lastRewardBlockTime: startTime,
            accCakePerShare: 0
        }));

        totalAllocPoint = singlePoolEnabled ? 1000 : 0;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public onlyOwner {
        require(lpTokenAdded[address(_lpToken)] == false, 'Pool for this token already exists!');
        lpTokenAdded[address(_lpToken)] = true;

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlockTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlockTime: lastRewardBlockTime,
            accCakePerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = singlePoolEnabled ? points.div(allocRatio) : 0;
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardBlockTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlockTime, block.timestamp);
            uint256 cakeReward = multiplier.mul(cakePerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.timestamp <= pool.lastRewardBlockTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlockTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlockTime, block.timestamp);
        uint256 cakeReward = multiplier.mul(cakePerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        // cake.mint(cakeReward); -- no need to mint, already on rewardVault
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlockTime = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeCakeTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            // Thanks for RugDoc advice
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before);
            // Thanks for RugDoc advice

            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        deposit(0, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeCakeTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        withdraw(0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe FISH transfer function, just in case if rounding error causes pool to not have enough FISH.
    function safeCakeTransfer(address _to, uint256 _amount) internal {
        IRewardVault(rewardVault).transfer(address(cake), _to, _amount);
    }

    // Update pool 0 allocation ratio. Can only be called by the owner.
    function setAllocRatio(uint8 _allocRatio) public onlyOwner {
        require(
            _allocRatio >= 1 && _allocRatio <= 10, 
            "Allocation ratio must be in range 1-10"
        );

        allocRatio = _allocRatio;
        massUpdatePools();
        updateStakingPool();
    }

    // reduce FISH emissions
    function reduceEmissions(uint256 _mintAmt) external onlyOwner {
        require(_mintAmt < cakePerSecond, "Only lower amount allowed.");
        require(_mintAmt.mul(100).div(cakePerSecond) >= 95, "Max 5% decrease per transaction.");
        cakePerSecond = _mintAmt;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp < startTime && block.timestamp < _startTime);
        startTime = _startTime;

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardBlockTime = startTime;
        }
    }

    function setSrcDistibutor(address _srcDistributor) external onlyOwner {
        require(srcDistributor == address(0));
        srcDistributor = _srcDistributor;
    }

    function flipSinglePoolEnabled() external onlyOwner {
        singlePoolEnabled = !singlePoolEnabled;
        massUpdatePools();
        updateStakingPool();
    }

    function anyExecute(bytes calldata data)
      external
      virtual
      returns (bool success, bytes memory result)
    {
      require(
          msg.sender == IAnycallV6Proxy(anyCallAddress).executor(), 
          "AnycallClient: not authorized"
      );

      address executor = IAnycallV6Proxy(anyCallAddress).executor();
      (address from, uint256 fromChainId,) = IAnycallExecutor(executor).context();
      require(from == srcDistributor, "SRC address wrong.");
      require(fromChainId == 42161, "SRC chain not arbitrum.");

      (
          uint256 _cakePerSecond
      ) = abi.decode(
          data,
          (uint256)
      );

      cakePerSecond = _cakePerSecond;
  }
}