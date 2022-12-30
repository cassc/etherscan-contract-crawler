// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/SignedSafeMath.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IStrategy.sol";

/// @notice The (older) MasterChef contract gives out a constant number of LQDR tokens per block.
/// It is the only address with minting rights for LQDR.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
contract MiniChefV2 is OwnableUpgradeable {
    using SafeMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of LQDR entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of LQDR to distribute per block.
    struct PoolInfo {
        uint256 accLqdrPerShare;
        uint256 lastRewardTime;
        uint256 allocPoint;
        uint256 depositFee;
    }

    /// @notice Address of LQDR contract.
    IERC20 public LQDR;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;
    /// @notice Address of each `IStrategy`.
    IStrategy[] public strategies;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public lqdrPerSecond;
    uint256 private ACC_LQDR_PRECISION;

    // Deposit Fee Address
    address public feeAddress;

    mapping (uint256 => address) public feeAddresses;

    address public treasury;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTime, uint256 lpSupply, uint256 accLqdrPerShare);
    event LogLqdrPerSecond(uint256 lqdrPerSecond);

    constructor() public {
    }

    function initialize(IERC20 _lqdr, address _feeAddress, address _treasury) public initializer {
        __Ownable_init();
        LQDR = _lqdr;
        feeAddress = _feeAddress;
        treasury = _treasury;
        ACC_LQDR_PRECISION = 1e18;
    }
    
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress || msg.sender == owner(), "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    function setFeeAddresses(uint256 pid, address _feeAddress) public {
        require(msg.sender == feeAddress || msg.sender == owner(), "setFeeAddress: FORBIDDEN");
        feeAddresses[pid] = _feeAddress;
    }
    
    function setTreasuryAddress(address _treasuryAddress) public {
        require(msg.sender == treasury || msg.sender == owner(), "setTreasuryAddress: FORBIDDEN");
        treasury = _treasuryAddress;
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(
        uint256 allocPoint, 
        IERC20 _lpToken, 
        IRewarder _rewarder, 
        IStrategy _strategy,
        uint256 _depositFee
    ) public onlyOwner {
        require(_depositFee <= 10000, "add: invalid deposit fee");
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);
        strategies.push(_strategy);

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint,
            lastRewardTime: block.timestamp,
            accLqdrPerShare: 0,
            depositFee: _depositFee
        }));
        emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's LQDR allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(
        uint256 _pid, 
        uint256 _allocPoint, 
        IRewarder _rewarder, 
        IStrategy _strategy,
        uint256 _depositFee, 
        bool overwrite
    ) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFee = _depositFee;
        if (overwrite) { 
            rewarder[_pid] = _rewarder; 

            if (address(strategies[_pid]) != address(_strategy)) {
                if (address(strategies[_pid]) != address(0)) {
                    _withdrawAllFromStrategy(_pid, strategies[_pid]);
                }
                if (address(_strategy) != address(0)) {
                    _depositAllToStrategy(_pid, _strategy);
                }
                strategies[_pid] = _strategy; 
            }
        }
        
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    function _withdrawAllFromStrategy(uint256 _pid, IStrategy _strategy) internal {
        IERC20 _lpToken = lpToken[_pid];
        uint256 _strategyBalance = _strategy.balanceOf();
        require(address(_lpToken) == _strategy.want(), '!lpToken');

        if (_strategyBalance > 0) {
            _strategy.withdraw(_strategyBalance);
            uint256 _currentBalance = _lpToken.balanceOf(address(this));

            require(_currentBalance >= _strategyBalance, '!balance1');

            _strategyBalance = _strategy.balanceOf();
            require(_strategyBalance == 0, '!balance2');
        }
    }

    function _depositAllToStrategy(uint256 _pid, IStrategy _strategy) internal {
        IERC20 _lpToken = lpToken[_pid];
        uint256 _strategyBalanceBefore = _strategy.balanceOf();
        uint256 _balanceBefore = _lpToken.balanceOf(address(this));
        require(address(_lpToken) == _strategy.want(), '!lpToken');

        if (_balanceBefore > 0) {
            _lpToken.safeTransfer(address(_strategy), _balanceBefore);
            _strategy.deposit();

            uint256 _strategyBalanceAfter = _strategy.balanceOf();
            uint256 _strategyBalanceDiff = _strategyBalanceAfter.sub(_strategyBalanceBefore);

            require(_strategyBalanceDiff == _balanceBefore, '!balance1');

            uint256 _balanceAfter = _lpToken.balanceOf(address(this));
            require(_balanceAfter == 0, '!balance2');
        }
    }

    /// @notice Sets the lqdr per second to be distributed. Can only be called by the owner.
    /// @param _lqdrPerSecond The amount of Lqdr to be distributed per second.
    function setLqdrPerSecond(uint256 _lqdrPerSecond) public onlyOwner {
        lqdrPerSecond = _lqdrPerSecond;
        emit LogLqdrPerSecond(_lqdrPerSecond);
    }

    /// @notice View function to see pending LQDR on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending LQDR reward for a given user.
    function pendingLqdr(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLqdrPerShare = pool.accLqdrPerShare;
        uint256 lpSupply;

        if (address(strategies[_pid]) != address(0)) {
            lpSupply = lpToken[_pid].balanceOf(address(this)).add(strategies[_pid].balanceOf());
        }
        else {
            lpSupply = lpToken[_pid].balanceOf(address(this));
        }

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 lqdrReward = time.mul(lqdrPerSecond).mul(pool.allocPoint) / totalAllocPoint;
            accLqdrPerShare = accLqdrPerShare.add(lqdrReward.mul(ACC_LQDR_PRECISION) / lpSupply);
        }
        pending = int256(user.amount.mul(accLqdrPerShare) / ACC_LQDR_PRECISION).sub(user.rewardDebt).toUInt256();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    function massHarvestFromStrategies() external {
        uint256 len = strategies.length;
        for (uint256 i = 0; i < len; ++i) {
            if (address(strategies[i]) != address(0)) {
                strategies[i].harvest();
            }
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply;

            if (address(strategies[pid]) != address(0)) {
                lpSupply = lpToken[pid].balanceOf(address(this)).add(strategies[pid].balanceOf());
            }
            else {
                lpSupply = lpToken[pid].balanceOf(address(this));
            }

            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 lqdrReward = time.mul(lqdrPerSecond).mul(pool.allocPoint) / totalAllocPoint;
                pool.accLqdrPerShare = pool.accLqdrPerShare
                    .add(lqdrReward.mul(ACC_LQDR_PRECISION).div(lpSupply));
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accLqdrPerShare);
        }
    }

    /// @notice Deposit LP tokens to MCV2 for LQDR allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];
        address _feeAddress = feeAddresses[pid];

        if (_feeAddress == address(0)) {
            _feeAddress = feeAddress;
        }

        // Effects
        uint256 depositFeeAmount = amount.mul(pool.depositFee).div(10000);
        user.amount = user.amount.add(amount).sub(depositFeeAmount);
        user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accLqdrPerShare) / ACC_LQDR_PRECISION));

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onLqdrReward(pid, to, to, 0, user.amount);
        }

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);
        lpToken[pid].safeTransfer(_feeAddress, depositFeeAmount);

        IStrategy _strategy = strategies[pid];
        if (address(_strategy) != address(0)) {
            uint256 _amount = lpToken[pid].balanceOf(address(this));
            lpToken[pid].safeTransfer(address(_strategy), _amount);
            _strategy.deposit();
        }

        emit Deposit(msg.sender, pid, amount, to);
    }

    function _withdraw(uint256 amount, uint256 pid, address to) internal returns (uint256) {
        uint256 balance = lpToken[pid].balanceOf(address(this));
        IStrategy strategy = strategies[pid];
        if (amount > balance) {
            uint256 missing = amount.sub(balance);
            uint256 withdrawn = strategy.withdraw(missing);
            amount = balance.add(withdrawn);
        }

        lpToken[pid].safeTransfer(to, amount);

        return amount;
    }

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accLqdrPerShare) / ACC_LQDR_PRECISION));
        user.amount = user.amount.sub(amount);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onLqdrReward(pid, msg.sender, to, 0, user.amount);
        }
        
        amount = _withdraw(amount, pid, to);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of LQDR rewards.
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedLqdr = int256(user.amount.mul(pool.accLqdrPerShare) / ACC_LQDR_PRECISION);
        uint256 _pendingLqdr = accumulatedLqdr.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedLqdr;

        // Interactions
        if (_pendingLqdr != 0) {
            LQDR.safeTransfer(to, _pendingLqdr);
        }
        
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onLqdrReward( pid, msg.sender, to, _pendingLqdr, user.amount);
        }

        emit Harvest(msg.sender, pid, _pendingLqdr);
    }
    
    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and LQDR rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedLqdr = int256(user.amount.mul(pool.accLqdrPerShare) / ACC_LQDR_PRECISION);
        uint256 _pendingLqdr = accumulatedLqdr.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedLqdr.sub(int256(amount.mul(pool.accLqdrPerShare) / ACC_LQDR_PRECISION));
        user.amount = user.amount.sub(amount);
        
        // Interactions
        LQDR.safeTransfer(to, _pendingLqdr);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onLqdrReward(pid, msg.sender, to, _pendingLqdr, user.amount);
        }

        _withdraw(amount, pid, to);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingLqdr);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onLqdrReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        amount = _withdraw(amount, pid, to);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}