// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../tokens/HelixToken.sol";
import "../interfaces/IReferralRegister.sol";
import "../interfaces/IFeeMinter.sol";
import "../timelock/OwnableTimelockUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract MasterChef is Initializable, PausableUpgradeable, OwnableUpgradeable, OwnableTimelockUpgradeable {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of HelixTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHelixTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accHelixTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. HelixTokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that HelixTokens distribution occurs.
        uint256 accHelixTokenPerShare; // Accumulated HelixTokens per share, times 1e12. See below.
    }

    // Used by bucket deposits and withdrawals to enable a caller to deposit lpTokens
    // and accrue yield into distinct, uniquely indentified "buckets" such that each
    // bucket can be interacted with individually and without affecting deposits and 
    // yields in other buckets
    struct BucketInfo {
        uint256 amount;             // How many LP tokens have been deposited into the bucket
        uint256 rewardDebt;         // Reward debt. See explanation in UserInfo
        uint256 yield;              // Accrued but unwithdrawn yield
    }
     
    // The HelixToken TOKEN!
    HelixToken public helixToken;

    // Called to get helix token to mint per block rates
    IFeeMinter public feeMinter;

    //Pools, Farms, Dev, Refs percent decimals
    uint256 public percentDec;

    //Pools and Farms percent from token per block
    uint256 public stakingPercent;

    //Developers percent from token per block
    uint256 public devPercent;

    // Dev address.
    address public devaddr;

    // Last block then develeper withdraw dev and ref fee
    uint256 public lastBlockDevWithdraw;

    // Bonus muliplier for early HelixToken makers.
    uint256 public BONUS_MULTIPLIER;

    // Referral Register contract
    IReferralRegister public refRegister;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The block number when HelixToken mining starts.
    uint256 public startBlock;

    // Deposited amount HelixToken in MasterChef
    uint256 public depositedHelix;

    // Maps poolId => depositorAddress => bucketId => BucketInfo
    // where the depositor is depositing funds into a uniquely identified deposit "bucket"
    // and where those funds are only accessible by the depositor
    // Used by the bucket deposit and withdraw functions
    mapping(uint256 => mapping(address => mapping(uint256 => BucketInfo))) public bucketInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Maps a lpToken address to a poolId
    mapping(address => uint256) public poolIds;

    event Deposit(
        address indexed user, 
        uint256 indexed pid, 
        uint256 amount
    );

    event Withdraw(
        address indexed user, 
        uint256 indexed pid, 
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    // Emitted when the owner adds a new LP Token to the pool
    event Added(uint256 indexed poolId, address indexed lpToken, bool withUpdate);

    // Emitted when the owner sets the pool alloc point
    event AllocPointSet(uint256 indexed poolId, uint256 allocPoint, bool withUpdate);

    // Emitted when the owner sets a new referral register contract
    event ReferralRegisterSet(address referralRegister);

    // Emitted when the pool is updated
    event PoolUpdated(uint256 indexed poolId);

    // Emitted when the owner sets a new dev address
    event DevAddressSet(address devAddress);

    // Emitted when the owner updates the helix per block rate
    event HelixPerBlockUpdated(uint256 rate);

    // Emitted when the feeMinter is set
    event SetFeeMinter(address indexed setter, address indexed feeMinter);
    
    // Emitted when a depositor deposits amount of lpToken into bucketId and stakes to poolId
    event BucketDeposit(
        address indexed depositor, 
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 amount
    );

    event BucketWithdraw(
        address indexed depositor, 
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 amount
    );

    event BucketWithdrawAmountTo(
        address indexed depositor, 
        address indexed recipient,
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 amount
    );

    event BucketWithdrawYieldTo(
        address indexed depositor, 
        address indexed recipient,
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 yield 
    );

    event UpdateBucket(
        address indexed depositor,
        uint256 indexed bucketId,
        uint256 indexed poolId
    );

    modifier isNotHelixPoolId(uint256 poolId) {
        require(poolId != 0, "MasterChef: invalid pool id");
        _;
    }

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "MasterChef: zero address");
        _;
    }

    function initialize(
        HelixToken _HelixToken,
        address _devaddr,
        address _feeMinter,
        uint256 _startBlock,
        uint256 _stakingPercent,
        uint256 _devPercent,
        IReferralRegister _referralRegister
    ) external initializer {
        __Ownable_init();
        __OwnableTimelock_init();
        helixToken = _HelixToken;
        devaddr = _devaddr;
        feeMinter = IFeeMinter(_feeMinter);
        startBlock = _startBlock != 0 ? _startBlock : block.number;
        stakingPercent = _stakingPercent;
        devPercent = _devPercent;
        lastBlockDevWithdraw = _startBlock != 0 ? _startBlock : block.number;
        refRegister = _referralRegister;
        
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _HelixToken,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accHelixTokenPerShare: 0
        }));
        poolIds[address(_HelixToken)] = 0;

        totalAllocPoint = 1000;
        percentDec = 1000000;
        BONUS_MULTIPLIER = 1;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyTimelock {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return the lpToken address associated with poolId _pid
    function getLpToken(uint256 _pid) external view returns(address) {
        return address(poolInfo[_pid].lpToken);
    }
    
    // Return the poolId associated with the lpToken address
    function getPoolId(address _lpToken) external view returns (uint256) {
        uint256 poolId = poolIds[_lpToken];
        if (poolId == 0) {
            require(_lpToken == address(helixToken), "MasterChef: token not added");
        }
        return poolId;
    }

    function withdrawDevAndRefFee() external {
        require(lastBlockDevWithdraw < block.number, "MasterChef: wait for new block");
        uint256 blockDelta = getMultiplier(lastBlockDevWithdraw, block.number);
        uint256 helixTokenReward = blockDelta * _getDevToMintPerBlock();
        lastBlockDevWithdraw = block.number;
        helixToken.mint(devaddr, helixTokenReward);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyTimelock {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + (_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accHelixTokenPerShare: 0
            })
        );

        uint256 poolId = poolInfo.length - 1;
        poolIds[address(_lpToken)] = poolId;

        emit Added(poolId, address(_lpToken), _withUpdate);
    }

    // Update the given pool's HelixToken allocation point. Can only be called by the owner.
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyTimelock {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - (poolInfo[_pid].allocPoint) + (_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;

        emit AllocPointSet(_pid, _allocPoint, _withUpdate);
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
         return (_to - _from) * (BONUS_MULTIPLIER);
    }

    // Set ReferralRegister address
    function setReferralRegister(address _address) external onlyOwner {
        refRegister = IReferralRegister(_address);
        emit ReferralRegisterSet(_address);
    }

    // View function to see pending HelixTokens on frontend.
    function pendingHelixToken(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accHelixTokenPerShare = pool.accHelixTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedHelix;
        }

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockDelta = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 toMintPerBlock = _getStakeToMintPerBlock();
            uint256 helixTokenReward = blockDelta * toMintPerBlock * (pool.allocPoint) / (totalAllocPoint);
            accHelixTokenPerShare = accHelixTokenPerShare + (helixTokenReward * (1e12) / (lpSupply));
        }

        uint256 pending = user.amount * (accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        return pending;
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
            lpSupply = depositedHelix;
        }
        if (lpSupply <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockDelta = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 toMintPerBlock = _getStakeToMintPerBlock();
        uint256 helixTokenReward = blockDelta * toMintPerBlock * pool.allocPoint / (totalAllocPoint);
        pool.accHelixTokenPerShare = pool.accHelixTokenPerShare + (helixTokenReward * (1e12) / (lpSupply));
        pool.lastRewardBlock = block.number;
        helixToken.mint(address(this), helixTokenReward);

        emit PoolUpdated(_pid);
    }

    // Deposit LP tokens to MasterChef for HelixToken allocation.
    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused isNotHelixPoolId(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount = user.amount + (_amount);
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);

        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(address(pool.lpToken), address(msg.sender), address(this), _amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external whenNotPaused isNotHelixPoolId(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "MasterChef: insufficient balance");

        updatePool(_pid);

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount -= _amount;
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);

        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Deposit _amount of lpToken into _bucketId and accrue yield by staking _amount to _poolId
    function bucketDeposit(
        uint256 _bucketId,          // Unique bucket to deposit _amount into
        uint256 _poolId,            // Pool to deposit _amount into
        uint256 _amount             // Amount of lpToken being deposited
    ) 
        external 
        whenNotPaused
        isNotHelixPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        updatePool(_poolId);

        // If the bucket already has already accrued rewards, 
        // increment the yield before resetting the rewardDebt
        if (bucket.amount > 0) {
            bucket.yield += bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        }
    
        // Update the bucket amount and reset the rewardDebt
        bucket.amount += _amount;
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);

        // Transfer amount of lpToken from caller to chef
        require(
            _amount <= pool.lpToken.allowance(msg.sender, address(this)), 
            "MasterChef: insufficient allowance"
        );
        TransferHelper.safeTransferFrom(address(pool.lpToken), msg.sender, address(this), _amount);

        emit BucketDeposit(msg.sender, _bucketId, _poolId, _amount);
    }

    // Withdraw _amount of lpToken and all accrued yield from _bucketId and _poolId
    function bucketWithdraw(uint256 _bucketId, uint256 _poolId, uint256 _amount) external whenNotPaused isNotHelixPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        require(_amount <= bucket.amount, "MasterChef: insufficient balance");

        updatePool(_poolId);
    
        // Calculate the total yield to withdraw
        uint256 pending = bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        uint256 yield = bucket.yield + pending;

        // Update the bucket state
        bucket.amount -= _amount;
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);
        bucket.yield = 0;

        // Withdraw the yield and lpToken
        refRegister.rewardStake(msg.sender, yield);
        safeHelixTokenTransfer(msg.sender, yield);
        TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);

        emit BucketWithdraw(msg.sender, _bucketId, _poolId, _amount);
    }

    // Withdraw _amount of lpToken from _bucketId and from _poolId
    // and send the withdrawn _amount to _recipient
    function bucketWithdrawAmountTo(
        address _recipient,
        uint256 _bucketId,
        uint256 _poolId, 
        uint256 _amount
    ) 
        external 
        whenNotPaused
        isNotZeroAddress(_recipient)
        isNotHelixPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];

        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];
        require(
            _amount <= bucket.amount, 
            "MasterChef: insufficient balance"
        );

        updatePool(_poolId);

        // Update the bucket state
        bucket.yield += bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        bucket.amount -= _amount;
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);

        // Transfer only lpToken to the recipient
        TransferHelper.safeTransfer(address(pool.lpToken), _recipient, _amount);

        emit BucketWithdrawAmountTo(msg.sender, _recipient, _bucketId, _poolId, _amount);
    }

    // Withdraw total yield in HelixToken from _bucketId and _poolId and send to _recipient
    function bucketWithdrawYieldTo(
        address _recipient,
        uint256 _bucketId,
        uint256 _poolId,
        uint256 _yield
    ) 
        external 
        whenNotPaused
        isNotZeroAddress(_recipient)
        isNotHelixPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        updatePool(_poolId);

        // Total yield is any pending yield plus any previously calculated yield
        uint256 pending = bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        uint256 yield = bucket.yield + pending;

        require(
            _yield <= yield,
            "MasterChef: insufficient balance"
        );

        // Update bucket state
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);
        yield -= _yield;

        refRegister.rewardStake(msg.sender, yield);
        safeHelixTokenTransfer(_recipient, _yield);

        emit BucketWithdrawYieldTo(msg.sender, _recipient, _bucketId, _poolId, _yield);
    }

    // Update _poolId and _bucketId yield and rewardDebt
    function updateBucket(uint256 _bucketId, uint256 _poolId) external isNotHelixPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        updatePool(_poolId);

        bucket.yield += bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);

        emit UpdateBucket(msg.sender, _bucketId, _poolId);
    }

    function getBucketYield(uint256 _bucketId, uint256 _poolId) 
        external 
        view 
        isNotHelixPoolId(_poolId)
        returns (uint256 yield) 
    {
        BucketInfo memory bucket = bucketInfo[_poolId][msg.sender][_bucketId];
        yield = bucket.yield;
    }

    // Stake HelixToken tokens to MasterChef
    function enterStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];

        updatePool(0);
        depositedHelix += _amount;

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount += _amount;
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);
        
        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(address(pool.lpToken), address(msg.sender), address(this), _amount);
        }

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw HelixToken tokens from STAKING.
    function leaveStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];

        updatePool(0);
        depositedHelix -= _amount;

        require(user.amount >= _amount, "MasterChef: insufficient balance");

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount -= _amount;
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);

        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);

        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    /// Return the portion of toMintPerBlock assigned to staking and farms
    function getStakeToMintPerBlock() external view returns (uint256) {
        return _getStakeToMintPerBlock();
    }

    /// Return the portion of toMintPerBlock assigned to dev team
    function getDevToMintPerBlock() external view returns (uint256) {
        return _getDevToMintPerBlock();
    }

    /// Return the toMintPerBlock rate assigned to this contract by the feeMinter
    function getToMintPerBlock() external view returns (uint256) {
        return _getToMintPerBlock();
    }
    // Safe HelixToken transfer function, just in case if rounding error causes pool to not have enough HelixTokens.
    function safeHelixTokenTransfer(address _to, uint256 _amount) internal {
        uint256 helixTokenBal = helixToken.balanceOf(address(this));
        uint256 toTransfer = _amount > helixTokenBal ? helixTokenBal : _amount;
        require(helixToken.transfer(_to, toTransfer), "MasterChef: transfer failed");
    }

    function setDevAddress(address _devaddr) external onlyTimelock {
        devaddr = _devaddr;
        emit DevAddressSet(_devaddr);
    }

    function setFeeMinter(address _feeMinter) external onlyTimelock {
        feeMinter = IFeeMinter(_feeMinter);
        emit SetFeeMinter(msg.sender, _feeMinter);
    }

    // Return the portion of toMintPerBlock assigned to staking and farms
    function _getStakeToMintPerBlock() private view returns (uint256) {
        return _getToMintPerBlock() * stakingPercent / percentDec;
    }

    // Return the portion of toMintPerBlock assigned to dev team
    function _getDevToMintPerBlock() private view returns (uint256) {
        return _getToMintPerBlock() * devPercent / percentDec;
    }

    // Return the toMintPerBlock rate assigned to this contract by the feeMinter
    function _getToMintPerBlock() private view returns (uint256) {
        require(address(feeMinter) != address(0), "MasterChef: fee minter unassigned");
        return feeMinter.getToMintPerBlock(address(this));
    }

    function setDevAndStakingPercents(uint256 _devPercent, uint256 _stakingPercent) external onlyOwner {
        require(_stakingPercent + _devPercent == 1000000, "MasterChef: invalid percents");
        stakingPercent = _stakingPercent;
        devPercent = _devPercent;
    }
}