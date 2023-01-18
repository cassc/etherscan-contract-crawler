// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

// imports
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// libraries
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LPStakingTime is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of STGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accEmissionPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accEmissionPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool, to distribute per block.
        uint256 lastRewardTime; // Last time that distribution occurs.
        uint256 accEmissionPerShare; // Accumulated Emissions per share, times 1e12. See below.
    }
    // Emissions token
    IERC20 public eToken;
    // Block time when bonus period ends.
    uint256 public bonusEndTime;
    // Tokens earned per second.
    uint256 public eTokenPerSecond;
    // Bonus multiplier for early makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Track which tokens have been added.
    mapping(address => bool) private addedLPTokens;

    mapping(uint256 => uint256) public lpBalances;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The time when mining starts.
    uint256 public startTime;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Add(uint256 allocPoint, address indexed lpToken);
    event Set(uint256 indexed pid, uint256 allocPoint);
    event TokensPerSec(uint256 eTokenPerSecond);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _eToken,
        uint256 _eTokenPerSecond,
        uint256 _startTime,
        uint256 _bonusEndTime
    ) {
        require(_startTime >= block.timestamp, "LPStaking: _startTime must be >= current block.timestamp");
        require(_bonusEndTime >= _startTime, "LPStaking: _bonusEndTime must be > than _startTime");
        require(_eToken != address(0x0), "LPStaking: _eToken cannot be 0x0");
        eToken = IERC20(_eToken);
        eTokenPerSecond = _eTokenPerSecond;
        startTime = _startTime;
        bonusEndTime = _bonusEndTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice handles adding a new LP token (Can only be called by the owner)
    /// @param _allocPoint The alloc point is used as the weight of the pool against all other alloc points added.
    /// @param _lpToken The lp token address
    function add(uint256 _allocPoint, IERC20 _lpToken) external onlyOwner {
        massUpdatePools();
        require(address(_lpToken) != address(0x0), "LPStaking: _lpToken cant be 0x0");
        require(addedLPTokens[address(_lpToken)] == false, "LPStaking: _lpToken already exists");
        addedLPTokens[address(_lpToken)] = true;
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({lpToken: _lpToken, allocPoint: _allocPoint, lastRewardTime: lastRewardTime, accEmissionPerShare: 0}));

        emit Add(_allocPoint, address(_lpToken));
    }

    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;

        emit Set(_pid, _allocPoint);
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndTime) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndTime) {
            return _to.sub(_from);
        } else {
            return bonusEndTime.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndTime));
        }
    }

    function pendingEmissionToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEmissionPerShare = pool.accEmissionPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 tokenReward = multiplier.mul(eTokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            accEmissionPerShare = accEmissionPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accEmissionPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || totalAllocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 tokenReward = multiplier.mul(eTokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accEmissionPerShare = pool.accEmissionPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardTime = block.timestamp;
    }

    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accEmissionPerShare).div(1e12).sub(user.rewardDebt);
            safeTokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accEmissionPerShare).div(1e12);
        lpBalances[_pid] = lpBalances[_pid].add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "LPStaking: withdraw _amount is too large");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEmissionPerShare).div(1e12).sub(user.rewardDebt);
        safeTokenTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accEmissionPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        lpBalances[_pid] = lpBalances[_pid].sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw without caring about rewards.
    /// @param _pid The pid specifies the pool
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 userAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), userAmount);
        lpBalances[_pid] = lpBalances[_pid].sub(userAmount);
        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    /// @notice Safe transfer function, just in case if rounding error causes pool to not have enough eToken.
    /// @param _to The address to transfer tokens to
    /// @param _amount The quantity to transfer
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 eTokenBal = eToken.balanceOf(address(this));
        require(eTokenBal >= _amount, "LPStakingTime: eTokenBal must be >= _amount");
        eToken.safeTransfer(_to, _amount);
    }

    function setETokenPerSecond(uint256 _eTokenPerSecond) external onlyOwner {
        massUpdatePools();
        eTokenPerSecond = _eTokenPerSecond;

        emit TokensPerSec(_eTokenPerSecond);
    }

    // Override the renounce ownership inherited by zeppelin ownable
    function renounceOwnership() public override onlyOwner {}
}