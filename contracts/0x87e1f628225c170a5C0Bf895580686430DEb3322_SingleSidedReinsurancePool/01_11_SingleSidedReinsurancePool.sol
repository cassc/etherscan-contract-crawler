// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMigration.sol";
import "./interfaces/IRiskPoolFactory.sol";
import "./interfaces/IRewarderFactory.sol";
import "./interfaces/ISingleSidedReinsurancePool.sol";
import "./interfaces/ISyntheticSSRPFactory.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IRiskPool.sol";
import "./libraries/TransferHelper.sol";

contract SingleSidedReinsurancePool is ISingleSidedReinsurancePool, ReentrancyGuard {
    address public owner;
    address public claimAssessor;
    address public migrateTo;
    address public syntheticSSRP;

    uint256 public LOCK_TIME = 1 days;
    uint256 public constant ACC_UNO_PRECISION = 1e18;
    uint256 public STAKING_START_TIME;

    address public rewarder;
    address public override riskPool;
    struct PoolInfo {
        uint128 lastRewardBlock;
        uint128 accUnoPerShare;
        uint256 unoMultiplierPerBlock;
    }

    struct UserInfo {
        uint256 lastWithdrawTime;
        uint256 rewardDebt;
        uint256 amount;
    }

    mapping(address => UserInfo) public userInfo;

    PoolInfo public poolInfo;

    event RiskPoolCreated(address indexed _SSRP, address indexed _pool);
    event StakedInPool(address indexed _staker, address indexed _pool, uint256 _amount);
    event LeftPool(address indexed _staker, address indexed _pool, uint256 _requestAmount);
    event LogUpdatePool(uint128 _lastRewardBlock, uint256 _lpSupply, uint256 _accUnoPerShare);
    event Harvest(address indexed _user, address indexed _receiver, uint256 _amount);
    event LogLeaveFromPendingSSRP(address indexed _user, uint256 _withdrawLpAmount, uint256 _withdrawUnoAmount);
    event PolicyClaim(address indexed _user, uint256 _claimAmount);
    event LogLpTransferInSSRP(address indexed _from, address indexed _to, uint256 _amount);
    event LogCreateRewarder(address indexed _SSRP, address indexed _rewarder, address _currency);
    event LogCreateSyntheticSSRP(address indexed _SSRP, address indexed _syntheticSSRP, address indexed _lpToken);
    event LogCancelWithdrawRequest(address indexed _user, uint256 _cancelAmount, uint256 _cancelAmountInUno);
    event LogMigrate(address indexed _user, address indexed _migrateTo, uint256 _migratedAmount);

    constructor(address _owner, address _claimAssessor) {
        owner = _owner;
        claimAssessor = _claimAssessor;
        STAKING_START_TIME = block.timestamp + 3 days;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    modifier onlyClaimAssessor() {
        require(msg.sender == claimAssessor, "UnoRe: Forbidden");
        _;
    }

    modifier isStartTime() {
        require(block.timestamp >= STAKING_START_TIME, "UnoRe: not available time");
        _;
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) external onlyOwner {
        require(_rewardMultiplier > 0, "UnoRe: zero value");
        poolInfo.unoMultiplierPerBlock = _rewardMultiplier;
    }

    function setClaimAssessor(address _claimAssessor) external onlyOwner {
        require(_claimAssessor != address(0), "UnoRe: zero address");
        claimAssessor = _claimAssessor;
    }

    function setMigrateTo(address _migrateTo) external onlyOwner {
        require(_migrateTo != address(0), "UnoRe: zero address");
        migrateTo = _migrateTo;
    }

    function setMinLPCapital(uint256 _minLPCapital) external onlyOwner {
        require(_minLPCapital > 0, "UnoRe: not allow zero value");
        IRiskPool(riskPool).setMinLPCapital(_minLPCapital);
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        require(_lockTime > 0, "UnoRe: not allow zero lock time");
        LOCK_TIME = _lockTime;
    }

    function setStakingStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > 0, "UnoRe: not allow zero start time");
        STAKING_START_TIME = _startTime;
    }

    /**
     * @dev create Risk pool with UNO from SSRP owner
     */
    function createRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _factory,
        address _currency,
        uint256 _rewardMultiplier
    ) external onlyOwner nonReentrant {
        require(riskPool == address(0), "UnoRe: risk pool created already");
        riskPool = IRiskPoolFactory(_factory).newRiskPool(_name, _symbol, address(this), _currency);
        poolInfo.lastRewardBlock = uint128(block.number);
        poolInfo.accUnoPerShare = 0;
        poolInfo.unoMultiplierPerBlock = _rewardMultiplier;
        emit RiskPoolCreated(address(this), riskPool);
    }

    function createRewarder(
        address _operator,
        address _factory,
        address _currency
    ) external onlyOwner nonReentrant {
        require(_factory != address(0), "UnoRe: rewarder factory no exist");
        rewarder = IRewarderFactory(_factory).newRewarder(_operator, _currency, address(this));
        emit LogCreateRewarder(address(this), rewarder, _currency);
    }

    function createSyntheticSSRP(address _owner, address _factory) external onlyOwner nonReentrant {
        require(_owner != address(0), "UnoRe: zero owner address");
        require(_factory != address(0), "UnoRe:zero factory address");
        require(riskPool != address(0), "UnoRe:zero LP token address");
        syntheticSSRP = ISyntheticSSRPFactory(_factory).newSyntheticSSRP(_owner, riskPool);
        emit LogCreateSyntheticSSRP(address(this), syntheticSSRP, riskPool);
    }

    function migrate() external nonReentrant {
        require(migrateTo != address(0), "UnoRe: zero address");
        _harvest(msg.sender);
        uint256 amount = userInfo[msg.sender].amount;
        bool isUnLocked = block.timestamp - userInfo[msg.sender].lastWithdrawTime > LOCK_TIME;
        uint256 migratedAmount = IRiskPool(riskPool).migrateLP(msg.sender, migrateTo, isUnLocked);
        IMigration(migrateTo).onMigration(msg.sender, amount, "");
        userInfo[msg.sender].amount = 0;
        userInfo[msg.sender].rewardDebt = 0;
        emit LogMigrate(msg.sender, migrateTo, migratedAmount);
    }

    function pendingUno(address _to) external view returns (uint256 pending) {
        uint256 tokenSupply = IERC20(riskPool).totalSupply();
        uint128 accUnoPerShare = poolInfo.accUnoPerShare;
        if (block.number > poolInfo.lastRewardBlock && tokenSupply != 0) {
            uint256 blocks = block.number - uint256(poolInfo.lastRewardBlock);
            uint256 unoReward = blocks * poolInfo.unoMultiplierPerBlock;
            accUnoPerShare = accUnoPerShare + uint128((unoReward * ACC_UNO_PRECISION) / tokenSupply);
        }
        uint256 userBalance = userInfo[_to].amount;
        pending = (userBalance * uint256(accUnoPerShare)) / ACC_UNO_PRECISION - userInfo[_to].rewardDebt;
    }

    function updatePool() public override {
        if (block.number > poolInfo.lastRewardBlock) {
            uint256 tokenSupply = IERC20(riskPool).totalSupply();
            if (tokenSupply > 0) {
                uint256 blocks = block.number - uint256(poolInfo.lastRewardBlock);
                uint256 unoReward = blocks * poolInfo.unoMultiplierPerBlock;
                poolInfo.accUnoPerShare = poolInfo.accUnoPerShare + uint128(((unoReward * ACC_UNO_PRECISION) / tokenSupply));
            }
            poolInfo.lastRewardBlock = uint128(block.number);
            emit LogUpdatePool(poolInfo.lastRewardBlock, tokenSupply, poolInfo.accUnoPerShare);
        }
    }

    function enterInPool(uint256 _amount) external override isStartTime nonReentrant {
        require(_amount != 0, "UnoRe: ZERO Value");
        updatePool();
        address token = IRiskPool(riskPool).currency();
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        TransferHelper.safeTransferFrom(token, msg.sender, riskPool, _amount);
        IRiskPool(riskPool).enter(msg.sender, _amount);
        userInfo[msg.sender].rewardDebt =
            userInfo[msg.sender].rewardDebt +
            ((_amount * 1e18 * uint256(poolInfo.accUnoPerShare)) / lpPriceUno) /
            ACC_UNO_PRECISION;
        userInfo[msg.sender].amount = userInfo[msg.sender].amount + ((_amount * 1e18) / lpPriceUno);
        emit StakedInPool(msg.sender, riskPool, _amount);
    }

    /**
     * @dev WR will be in pending for 10 days at least
     */
    function leaveFromPoolInPending(uint256 _amount) external override isStartTime nonReentrant {
        _harvest(msg.sender);
        // Withdraw desired amount from pool
        uint256 amount = userInfo[msg.sender].amount;
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        (uint256 pendingAmount, , ) = IRiskPool(riskPool).getWithdrawRequest(msg.sender);
        require(((amount - pendingAmount) * lpPriceUno) / 1e18 >= _amount, "UnoRe: withdraw amount overflow");
        IRiskPool(riskPool).leaveFromPoolInPending(msg.sender, _amount);

        userInfo[msg.sender].lastWithdrawTime = block.timestamp;
        emit LeftPool(msg.sender, riskPool, _amount);
    }

    /**
     * @dev user can submit claim again and receive his funds into his wallet after 10 days since last WR.
     */
    function leaveFromPending() external override isStartTime nonReentrant {
        require(block.timestamp - userInfo[msg.sender].lastWithdrawTime >= LOCK_TIME, "UnoRe: Locked time");
        _harvest(msg.sender);
        uint256 amount = userInfo[msg.sender].amount;
        (uint256 pendingAmount, , ) = IRiskPool(riskPool).getWithdrawRequest(msg.sender);
        uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
        userInfo[msg.sender].rewardDebt =
            accumulatedUno -
            ((pendingAmount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION);
        (uint256 withdrawAmount, uint256 withdrawAmountInUNO) = IRiskPool(riskPool).leaveFromPending(msg.sender);
        userInfo[msg.sender].amount = amount - withdrawAmount;
        emit LogLeaveFromPendingSSRP(msg.sender, withdrawAmount, withdrawAmountInUNO);
    }

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external override nonReentrant {
        require(msg.sender == address(riskPool), "UnoRe: not allow others transfer");
        if (_from != syntheticSSRP && _to != syntheticSSRP) {
            _harvest(_from);
            uint256 amount = userInfo[_from].amount;
            (uint256 pendingAmount, , ) = IRiskPool(riskPool).getWithdrawRequest(_from);
            require(amount - pendingAmount >= _amount, "UnoRe: balance overflow");
            uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
            userInfo[_from].rewardDebt = accumulatedUno - ((_amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION);
            userInfo[_from].amount = amount - _amount;

            userInfo[_to].rewardDebt =
                userInfo[_to].rewardDebt +
                ((_amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION);
            userInfo[_to].amount = userInfo[_to].amount + _amount;

            emit LogLpTransferInSSRP(_from, _to, _amount);
        }
    }

    function harvest(address _to) external override isStartTime nonReentrant {
        _harvest(_to);
    }

    function _harvest(address _to) private {
        updatePool();
        uint256 amount = userInfo[_to].amount;
        uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
        uint256 _pendingUno = accumulatedUno - userInfo[_to].rewardDebt;

        // Effects
        userInfo[msg.sender].rewardDebt = accumulatedUno;
        uint256 rewardAmount = 0;

        if (rewarder != address(0) && _pendingUno != 0) {
            rewardAmount = IRewarder(rewarder).onReward(_to, _pendingUno);
        }

        emit Harvest(msg.sender, _to, rewardAmount);
    }

    function cancelWithdrawRequest() external nonReentrant {
        (uint256 cancelAmount, uint256 cancelAmountInUno) = IRiskPool(riskPool).cancelWithrawRequest(msg.sender);
        emit LogCancelWithdrawRequest(msg.sender, cancelAmount, cancelAmountInUno);
    }

    function policyClaim(address _to, uint256 _amount) external onlyClaimAssessor isStartTime nonReentrant {
        require(_to != address(0), "UnoRe: zero address");
        require(_amount > 0, "UnoRe: zero amount");
        uint256 realClaimAmount = IRiskPool(riskPool).policyClaim(_to, _amount);
        emit PolicyClaim(_to, realClaimAmount);
    }

    function getStakedAmountPerUser(address _to) external view returns (uint256 unoAmount, uint256 lpAmount) {
        lpAmount = userInfo[_to].amount;
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        unoAmount = (lpAmount * lpPriceUno) / 1e18;
    }

    /**
     * @dev get withdraw request amount in pending per user in UNO
     */
    function getWithdrawRequestPerUser(address _user)
        external
        view
        returns (
            uint256 pendingAmount,
            uint256 pendingAmountInUno,
            uint256 originUnoAmount,
            uint256 requestTime
        )
    {
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        (pendingAmount, requestTime, originUnoAmount) = IRiskPool(riskPool).getWithdrawRequest(_user);
        pendingAmountInUno = (pendingAmount * lpPriceUno) / 1e18;
    }

    /**
     * @dev get total withdraw request amount in pending for the risk pool in UNO
     */
    function getTotalWithdrawPendingAmount() external view returns (uint256) {
        return IRiskPool(riskPool).getTotalWithdrawRequestAmount();
    }
}