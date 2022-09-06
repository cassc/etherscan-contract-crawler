// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../util/Initializable.sol";
import "../interfaces/IBSLendingPair.sol";
import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IRewardDistributorManager.sol";

abstract contract RewardDistributorStorageV1 is IRewardDistributor, Initializable {
    /// @dev PoolInfo
    struct PoolInfo {
        IERC20 receiptTokenAddr;
        uint256 lastUpdateTimestamp;
        uint256 accRewardTokenPerShare;
        uint128 allocPoint;
    }

    /// @dev UserInfo
    struct UserInfo {
        uint256 lastAccRewardTokenPerShare;
        uint256 pendingReward; // pending user reward to be withdrawn
        uint256 lastUpdateTimestamp; // last time user accumulated rewards
    }

    /// @notice reward distributor name
    string public name;

    /// @dev bool to check if rewarddistributor is activate
    bool public activated;

    /// @notice reward token to be distributed to users
    IERC20 public rewardToken;

    /// @notice poolInfo
    PoolInfo[] public poolInfo;

    /// @notice userInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice queue for receipt tokens awaiting activation
    address[] public pendingRewardActivation;

    /// @dev token -> pool id, use the `getTokenPoolID` function
    /// to get a receipt token pool id
    mapping(address => uint256) internal tokenPoolIDPair;

    /// @dev totalAllocPoint
    uint256 public totalAllocPoint;

    /// @notice start timestamp for distribution to begin
    uint256 public startTimestamp;

    /// @notice end timestamp for distribution to end
    uint256 public override endTimestamp;

    /// @notice responsible for updating reward distribution
    address public guardian;

    /// @notice rewardAmountDistributePerSecond scaled in 1e18
    uint256 public rewardAmountDistributePerSecond;
}

contract RewardDistributor is RewardDistributorStorageV1 {
    using SafeERC20 for IERC20;

    /// @notice manager
    IRewardDistributorManager public immutable rewardDistributorManager;

    uint256 private constant SHARE_SCALE = 1e12;

    /// @dev grace period for user to claim rewards after endTimestamp
    uint256 private constant CLAIM_REWARD_GRACE_PERIOD = 30 days;

    /// @dev period for users to withdraw rewards after endTimestamp before it can be
    /// reclaimed by the guardian to prevent funds being locked in contract
    uint256 private constant WITHDRAW_REWARD_GRACE_PERIOD = 90 days;

    event Withdraw(
        address indexed distributor,
        address indexed user,
        uint256 indexed poolId,
        address _to,
        uint256 amount
    );

    event AddDistribution(
        address indexed lendingPair,
        address indexed distributor,
        DistributorConfigVars vars,
        uint256 timestamp
    );

    event UpdateDistribution(uint256 indexed pid, uint256 newAllocPoint, uint256 timestamp);

    event AccumulateReward(address indexed receiptToken, uint256 indexed pid, address user);

    event WithdrawUnclaimedReward(address indexed distributor, uint256 amount, uint256 timestamp);

    event ActivateReward(address indexed distributor, uint256 timestamp);

    event UpdateEndTimestamp(address indexed distributor, uint256 newTimestamp, uint256 timestamp);

    modifier onlyGuardian {
        require(msg.sender == guardian, "ONLY_GUARDIAN");
        _;
    }

    /// @notice create a distributor
    /// @param _rewardDistributorManager the reward distributor manager address
    constructor(address _rewardDistributorManager) {
        require(_rewardDistributorManager != address(0), "INVALID_MANAGER");
        rewardDistributorManager = IRewardDistributorManager(_rewardDistributorManager);
    }

    /// @dev accumulates reward for a depositor
    /// @param _tokenAddr token to reward
    /// @param _user user to accumulate reward for
    function accumulateReward(address _tokenAddr, address _user) external override {
        require(_tokenAddr != address(0), "INVALID_ADDR");
        uint256 pid = getTokenPoolID(_tokenAddr);

        updatePoolAndDistributeUserReward(pid, _user);
        emit AccumulateReward(_tokenAddr, pid, _user);
    }

    /// @dev intialize
    /// @param _rewardToken asset to distribute
    /// @param _amountDistributePerSecond amount to distributer per second
    /// @param _startTimestamp time to start distributing
    /// @param _endTimestamp time to end distributing
    /// @param _guardian distributor guardian
    function initialize(
        string calldata _name,
        IERC20 _rewardToken,
        uint256 _amountDistributePerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _guardian
    ) external override initializer {
        require(address(_rewardToken) != address(0), "INVALID_TOKEN");
        require(_guardian != address(0), "INVALID_GUARDIAN");
        require(_amountDistributePerSecond > 0, "INVALID_DISTRIBUTE");
        require(_startTimestamp > 0, "INVALID_TIMESTAMP_1");
        require(_endTimestamp > 0, "INVALID_TIMESTAMP_2");
        require(_endTimestamp > _startTimestamp, "INVALID_TIMESTAMP_3");

        name = _name;
        rewardToken = _rewardToken;
        rewardAmountDistributePerSecond = _amountDistributePerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        guardian = _guardian;

        emit Initialized(
            _rewardToken,
            _amountDistributePerSecond,
            _startTimestamp,
            _endTimestamp,
            _guardian,
            block.timestamp
        );
    }

    struct DistributorConfigVars {
        uint128 collateralTokenAllocPoint;
        uint128 debtTokenAllocPoint;
        uint128 borrowAssetTokenAllocPoint;
    }

    /// @dev Add a distribution param for a lending pair
    /// @param _allocPoints specifies the allocation points
    /// @param _lendingPair the lending pair being added
    function add(DistributorConfigVars calldata _allocPoints, IBSLendingPair _lendingPair)
        external
        onlyGuardian
    {
        uint256 _startTimestamp = startTimestamp;

        // guardian can not add more once distribution starts
        require(block.timestamp < _startTimestamp, "DISTRIBUTION_STARTED");

        if (_allocPoints.collateralTokenAllocPoint > 0) {
            createPool(
                _allocPoints.collateralTokenAllocPoint,
                _lendingPair.wrappedCollateralAsset(),
                _startTimestamp
            );
        }

        if (_allocPoints.debtTokenAllocPoint > 0) {
            createPool(_allocPoints.debtTokenAllocPoint, _lendingPair.debtToken(), _startTimestamp);
        }

        if (_allocPoints.borrowAssetTokenAllocPoint > 0) {
            createPool(
                _allocPoints.borrowAssetTokenAllocPoint,
                _lendingPair.wrapperBorrowedAsset(),
                _startTimestamp
            );
        }

        emit AddDistribution(address(_lendingPair), address(this), _allocPoints, block.timestamp);
    }

    /// @notice activatePendingRewards Activate pending reward in the manger
    function activatePendingRewards() external {
        for (uint256 i = 0; i < pendingRewardActivation.length; i++) {
            rewardDistributorManager.activateReward(pendingRewardActivation[i]);
        }

        // reset storage
        delete pendingRewardActivation;

        // set activated to true
        if (!activated) activated = true;

        emit ActivateReward(address(this), block.timestamp);
    }

    /// @notice set update allocation point for a pool
    function set(
        uint256 _pid,
        uint128 _allocPoint,
        bool _withUpdate
    ) public onlyGuardian {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        emit UpdateDistribution(_pid, _allocPoint, block.timestamp);
    }

    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to > endTimestamp) _to = endTimestamp;
        return _to - _from;
    }

    function pendingRewardToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 totalSupply = pool.receiptTokenAddr.totalSupply();

        if (block.timestamp > pool.lastUpdateTimestamp && totalSupply != 0) {
            accRewardTokenPerShare = calculatePoolReward(pool, totalSupply);
        }

        uint256 amount = pool.receiptTokenAddr.balanceOf(_user);

        return calculatePendingReward(amount, accRewardTokenPerShare, user);
    }

    /// @dev return accumulated reward share for the pool
    function calculatePoolReward(PoolInfo memory pool, uint256 totalSupply)
        internal
        view
        returns (uint256 accRewardTokenPerShare)
    {
        if (pool.lastUpdateTimestamp >= endTimestamp) {
            return pool.accRewardTokenPerShare;
        }

        uint256 multiplier = getMultiplier(pool.lastUpdateTimestamp, block.timestamp);
        uint256 tokenReward =
            (multiplier * rewardAmountDistributePerSecond * pool.allocPoint) / totalAllocPoint;
        accRewardTokenPerShare =
            pool.accRewardTokenPerShare +
            ((tokenReward * SHARE_SCALE) / totalSupply);
    }

    /// @notice Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid pool id
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastUpdateTimestamp) {
            return;
        }
        uint256 totalSupply = pool.receiptTokenAddr.totalSupply();

        if (totalSupply == 0) {
            pool.lastUpdateTimestamp = block.timestamp;
            return;
        }

        pool.accRewardTokenPerShare = calculatePoolReward(pool, totalSupply);
        pool.lastUpdateTimestamp = block.timestamp > endTimestamp ? endTimestamp : block.timestamp;
    }

    /// @dev user to withdraw accumulated rewards from a pool
    /// @param _pid pool id
    /// @param _to address to transfer rewards to
    function withdraw(uint256 _pid, address _to) external {
        require(_to != address(0), "INVALID_TO");

        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePoolAndDistributeUserReward(_pid, msg.sender);

        uint256 amountToWithdraw = user.pendingReward;
        if (amountToWithdraw == 0) return;

        // set pending reward to 0
        user.pendingReward = 0;
        safeTokenTransfer(_to, amountToWithdraw);

        emit Withdraw(address(this), msg.sender, _pid, _to, amountToWithdraw);
    }

    /// @dev update the end timestamp
    /// @param _newEndTimestamp new end timestamp
    function updateEndTimestamp(uint256 _newEndTimestamp) external onlyGuardian {
        require(
            block.timestamp < endTimestamp && _newEndTimestamp > endTimestamp,
            "INVALID_TIMESTAMP"
        );
        endTimestamp = _newEndTimestamp;

        emit UpdateEndTimestamp(address(this), _newEndTimestamp, block.timestamp);
    }

    /// @dev withdraw unclaimed rewards
    /// @param _to address to withdraw to
    function withdrawUnclaimedRewards(address _to) external onlyGuardian {
        require(
            block.timestamp > endTimestamp + WITHDRAW_REWARD_GRACE_PERIOD,
            "REWARD_PERIOD_ACTIVE"
        );
        uint256 amount = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(_to, amount);

        emit WithdrawUnclaimedReward(address(this), amount, block.timestamp);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_amount > balance) {
            rewardToken.safeTransfer(_to, balance);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }

    function getTokenPoolID(address _receiptTokenAddr) public view returns (uint256 poolId) {
        poolId = tokenPoolIDPair[address(_receiptTokenAddr)] - 1;
    }

    function calculatePendingReward(
        uint256 _amount,
        uint256 _accRewardTokenPerShare,
        UserInfo memory _userInfo
    ) internal view returns (uint256 pendingReward) {
        if (
            _userInfo.lastUpdateTimestamp >= endTimestamp ||
            block.timestamp > endTimestamp + CLAIM_REWARD_GRACE_PERIOD ||
            _amount == 0
        ) return 0;

        uint256 rewardDebt = (_amount * _userInfo.lastAccRewardTokenPerShare) / SHARE_SCALE;
        pendingReward = ((_amount * _accRewardTokenPerShare) / SHARE_SCALE) - rewardDebt;
        pendingReward += _userInfo.pendingReward;
    }

    /// @dev update pool and accrue rewards for user
    /// @param _pid pool id
    /// @param _user user to update rewards for
    function updatePoolAndDistributeUserReward(uint256 _pid, address _user) internal {
        if (activated == false || block.timestamp < startTimestamp) return;

        // update the pool
        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];

        if (_user != address(0)) {
            UserInfo storage user = userInfo[_pid][_user];
            uint256 amount = pool.receiptTokenAddr.balanceOf(_user);
            user.pendingReward = calculatePendingReward(amount, pool.accRewardTokenPerShare, user);
            user.lastAccRewardTokenPerShare = pool.accRewardTokenPerShare;
            user.lastUpdateTimestamp = block.timestamp;
        }
    }

    function createPool(
        uint128 _allocPoint,
        IERC20 _receiptTokenAddr,
        uint256 _lastUpdateTimestamp
    ) internal {
        require(address(_receiptTokenAddr) != address(0), "invalid_addr");
        require(tokenPoolIDPair[address(_receiptTokenAddr)] == 0, "token_exists");

        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolInfo.push(
            PoolInfo({
                receiptTokenAddr: _receiptTokenAddr,
                allocPoint: _allocPoint,
                lastUpdateTimestamp: _lastUpdateTimestamp,
                accRewardTokenPerShare: 0
            })
        );

        tokenPoolIDPair[address(_receiptTokenAddr)] = poolInfo.length;
        pendingRewardActivation.push(address(_receiptTokenAddr));
    }
}