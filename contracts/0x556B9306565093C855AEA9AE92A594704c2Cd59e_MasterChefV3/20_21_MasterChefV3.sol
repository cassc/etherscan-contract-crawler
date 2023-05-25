// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/SafeCast.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/INonfungiblePositionManagerStruct.sol";
import "./interfaces/IPancakeV3Pool.sol";
import "./interfaces/IMasterChefV2.sol";
import "./interfaces/ILMPool.sol";
import "./interfaces/ILMPoolDeployer.sol";
import "./interfaces/IFarmBooster.sol";
import "./interfaces/IWETH.sol";
import "./utils/Multicall.sol";
import "./Enumerable.sol";

contract MasterChefV3 is INonfungiblePositionManagerStruct, Multicall, Ownable, ReentrancyGuard, Enumerable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    struct PoolInfo {
        uint256 allocPoint;
        // V3 pool address
        IPancakeV3Pool v3Pool;
        // V3 pool token0 address
        address token0;
        // V3 pool token1 address
        address token1;
        // V3 pool fee
        uint24 fee;
        // total liquidity staking in the pool
        uint256 totalLiquidity;
        // total boost liquidity staking in the pool
        uint256 totalBoostLiquidity;
    }

    struct UserPositionInfo {
        uint128 liquidity;
        uint128 boostLiquidity;
        int24 tickLower;
        int24 tickUpper;
        uint256 rewardGrowthInside;
        uint256 reward;
        address user;
        uint256 pid;
        uint256 boostMultiplier;
    }

    uint256 public poolLength;
    /// @notice Info of each MCV3 pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    /// @notice userPositionInfos[tokenId] => UserPositionInfo
    /// @dev TokenId is unique, and we can query the pid by tokenId.
    mapping(uint256 => UserPositionInfo) public userPositionInfos;

    /// @notice v3PoolPid[token0][token1][fee] => pid
    mapping(address => mapping(address => mapping(uint24 => uint256))) v3PoolPid;
    /// @notice v3PoolAddressPid[v3PoolAddress] => pid
    mapping(address => uint256) public v3PoolAddressPid;

    /// @notice Address of CAKE contract.
    IERC20 public immutable CAKE;

    /// @notice Address of WETH contract.
    address public immutable WETH;

    /// @notice Address of Receiver contract.
    address public receiver;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    /// @notice Address of liquidity mining pool deployer contract.
    ILMPoolDeployer public LMPoolDeployer;

    /// @notice Address of farm booster contract.
    IFarmBooster public FARM_BOOSTER;

    /// @notice Only use for emergency situations.
    bool public emergency;

    /// @notice Total allocation points. Must be the sum of all pools' allocation points.
    uint256 public totalAllocPoint;

    uint256 public latestPeriodNumber;
    uint256 public latestPeriodStartTime;
    uint256 public latestPeriodEndTime;
    uint256 public latestPeriodCakePerSecond;

    /// @notice Address of the operator.
    address public operatorAddress;
    /// @notice Default period duration.
    uint256 public PERIOD_DURATION = 1 days;
    uint256 public constant MAX_DURATION = 30 days;
    uint256 public constant MIN_DURATION = 1 days;
    uint256 public constant PRECISION = 1e12;
    /// @notice Basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice Hard limit for maxmium boost factor, it must greater than BOOST_PRECISION
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;
    uint256 constant Q128 = 0x100000000000000000000000000000000;
    uint256 constant MAX_U256 = type(uint256).max;

    /// @notice Record the cake amount belong to MasterChefV3.
    uint256 public cakeAmountBelongToMC;

    error ZeroAddress();
    error NotOwnerOrOperator();
    error NoBalance();
    error NotPancakeNFT();
    error InvalidNFT();
    error NotOwner();
    error NoLiquidity();
    error InvalidPeriodDuration();
    error NoLMPool();
    error InvalidPid();
    error DuplicatedPool(uint256 pid);
    error NotEmpty();
    error WrongReceiver();
    error InconsistentAmount();
    error InsufficientAmount();

    event AddPool(uint256 indexed pid, uint256 allocPoint, IPancakeV3Pool indexed v3Pool, ILMPool indexed lmPool);
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event Deposit(
        address indexed from,
        uint256 indexed pid,
        uint256 indexed tokenId,
        uint256 liquidity,
        int24 tickLower,
        int24 tickUpper
    );
    event Withdraw(address indexed from, address to, uint256 indexed pid, uint256 indexed tokenId);
    event UpdateLiquidity(
        address indexed from,
        uint256 indexed pid,
        uint256 indexed tokenId,
        int128 liquidity,
        int24 tickLower,
        int24 tickUpper
    );
    event NewOperatorAddress(address operator);
    event NewLMPoolDeployerAddress(address deployer);
    event NewReceiver(address receiver);
    event NewPeriodDuration(uint256 periodDuration);
    event Harvest(address indexed sender, address to, uint256 indexed pid, uint256 indexed tokenId, uint256 reward);
    event NewUpkeepPeriod(
        uint256 indexed periodNumber,
        uint256 startTime,
        uint256 endTime,
        uint256 cakePerSecond,
        uint256 cakeAmount
    );
    event UpdateUpkeepPeriod(
        uint256 indexed periodNumber,
        uint256 oldEndTime,
        uint256 newEndTime,
        uint256 remainingCake
    );
    event UpdateFarmBoostContract(address indexed farmBoostContract);
    event SetEmergency(bool emergency);

    modifier onlyOwnerOrOperator() {
        if (msg.sender != operatorAddress && msg.sender != owner()) revert NotOwnerOrOperator();
        _;
    }

    modifier onlyValidPid(uint256 _pid) {
        if (_pid == 0 || _pid > poolLength) revert InvalidPid();
        _;
    }

    modifier onlyReceiver() {
        require(receiver == msg.sender, "Not receiver");
        _;
    }

    /**
     * @dev Throws if caller is not the boost contract.
     */
    modifier onlyBoostContract() {
        require(address(FARM_BOOSTER) == msg.sender, "Not farm boost contract");
        _;
    }

    /// @param _CAKE The CAKE token contract address.
    /// @param _nonfungiblePositionManager the NFT position manager contract address.
    constructor(IERC20 _CAKE, INonfungiblePositionManager _nonfungiblePositionManager, address _WETH) {
        CAKE = _CAKE;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        WETH = _WETH;
    }

    /// @notice Returns the cake per second , period end time.
    /// @param _pid The pool pid.
    /// @return cakePerSecond Cake reward per second.
    /// @return endTime Period end time.
    function getLatestPeriodInfoByPid(uint256 _pid) public view returns (uint256 cakePerSecond, uint256 endTime) {
        if (totalAllocPoint > 0) {
            cakePerSecond = (latestPeriodCakePerSecond * poolInfo[_pid].allocPoint) / totalAllocPoint;
        }
        endTime = latestPeriodEndTime;
    }

    /// @notice Returns the cake per second , period end time. This is for liquidity mining pool.
    /// @param _v3Pool Address of the V3 pool.
    /// @return cakePerSecond Cake reward per second.
    /// @return endTime Period end time.
    function getLatestPeriodInfo(address _v3Pool) public view returns (uint256 cakePerSecond, uint256 endTime) {
        if (totalAllocPoint > 0) {
            cakePerSecond =
                (latestPeriodCakePerSecond * poolInfo[v3PoolAddressPid[_v3Pool]].allocPoint) /
                totalAllocPoint;
        }
        endTime = latestPeriodEndTime;
    }

    /// @notice View function for checking pending CAKE rewards.
    /// @dev The pending cake amount is based on the last state in LMPool. The actual amount will happen whenever liquidity changes or harvest.
    /// @param _tokenId Token Id of NFT.
    /// @return reward Pending reward.
    function pendingCake(uint256 _tokenId) external view returns (uint256 reward) {
        UserPositionInfo memory positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.pid != 0) {
            PoolInfo memory pool = poolInfo[positionInfo.pid];
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (address(LMPool) != address(0)) {
                uint256 rewardGrowthInside = LMPool.getRewardGrowthInside(
                    positionInfo.tickLower,
                    positionInfo.tickUpper
                );
                if (
                    rewardGrowthInside > positionInfo.rewardGrowthInside &&
                    MAX_U256 / (rewardGrowthInside - positionInfo.rewardGrowthInside) > positionInfo.boostLiquidity
                )
                    reward =
                        ((rewardGrowthInside - positionInfo.rewardGrowthInside) * positionInfo.boostLiquidity) /
                        Q128;
            }
            reward += positionInfo.reward;
        }
    }

    /// @notice For emergency use only.
    function setEmergency(bool _emergency) external onlyOwner {
        emergency = _emergency;
        emit SetEmergency(emergency);
    }

    function setReceiver(address _receiver) external onlyOwner {
        if (_receiver == address(0)) revert ZeroAddress();
        if (CAKE.allowance(_receiver, address(this)) != type(uint256).max) revert();
        receiver = _receiver;
        emit NewReceiver(_receiver);
    }

    function setLMPoolDeployer(ILMPoolDeployer _LMPoolDeployer) external onlyOwner {
        if (address(_LMPoolDeployer) == address(0)) revert ZeroAddress();
        LMPoolDeployer = _LMPoolDeployer;
        emit NewLMPoolDeployerAddress(address(_LMPoolDeployer));
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// @notice One v3 pool can only create one pool.
    /// @param _allocPoint Number of allocation points for the new pool.
    /// @param _v3Pool Address of the V3 pool.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function add(uint256 _allocPoint, IPancakeV3Pool _v3Pool, bool _withUpdate) external onlyOwner {
        if (_withUpdate) massUpdatePools();

        ILMPool lmPool = LMPoolDeployer.deploy(_v3Pool);

        totalAllocPoint += _allocPoint;
        address token0 = _v3Pool.token0();
        address token1 = _v3Pool.token1();
        uint24 fee = _v3Pool.fee();
        if (v3PoolPid[token0][token1][fee] != 0) revert DuplicatedPool(v3PoolPid[token0][token1][fee]);
        if (IERC20(token0).allowance(address(this), address(nonfungiblePositionManager)) == 0)
            IERC20(token0).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        if (IERC20(token1).allowance(address(this), address(nonfungiblePositionManager)) == 0)
            IERC20(token1).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        unchecked {
            poolLength++;
        }
        poolInfo[poolLength] = PoolInfo({
            allocPoint: _allocPoint,
            v3Pool: _v3Pool,
            token0: token0,
            token1: token1,
            fee: fee,
            totalLiquidity: 0,
            totalBoostLiquidity: 0
        });

        v3PoolPid[token0][token1][fee] = poolLength;
        v3PoolAddressPid[address(_v3Pool)] = poolLength;
        emit AddPool(poolLength, _allocPoint, _v3Pool, lmPool);
    }

    /// @notice Update the given pool's CAKE allocation point. Can only be called by the owner.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _allocPoint New number of allocation points for the pool.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner onlyValidPid(_pid) {
        uint32 currentTime = uint32(block.timestamp);
        PoolInfo storage pool = poolInfo[_pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) != address(0)) {
            LMPool.accumulateReward(currentTime);
        }

        if (_withUpdate) massUpdatePools();
        totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.allocPoint = _allocPoint;
        emit SetPool(_pid, _allocPoint);
    }

    struct DepositCache {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    /// @notice Upon receiving a ERC721
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external nonReentrant returns (bytes4) {
        if (msg.sender != address(nonfungiblePositionManager)) revert NotPancakeNFT();
        DepositCache memory cache;
        (
            ,
            ,
            cache.token0,
            cache.token1,
            cache.fee,
            cache.tickLower,
            cache.tickUpper,
            cache.liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);
        if (cache.liquidity == 0) revert NoLiquidity();
        uint256 pid = v3PoolPid[cache.token0][cache.token1][cache.fee];
        if (pid == 0) revert InvalidNFT();
        PoolInfo memory pool = poolInfo[pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) == address(0)) revert NoLMPool();

        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];

        positionInfo.tickLower = cache.tickLower;
        positionInfo.tickUpper = cache.tickUpper;
        positionInfo.user = _from;
        positionInfo.pid = pid;
        // Need to update LMPool.
        LMPool.accumulateReward(uint32(block.timestamp));
        updateLiquidityOperation(positionInfo, _tokenId, 0);

        positionInfo.rewardGrowthInside = LMPool.getRewardGrowthInside(cache.tickLower, cache.tickUpper);

        // Update Enumerable
        addToken(_from, _tokenId);
        emit Deposit(_from, pid, _tokenId, cache.liquidity, cache.tickLower, cache.tickUpper);

        return this.onERC721Received.selector;
    }

    /// @notice harvest cake from pool.
    /// @param _tokenId Token Id of NFT.
    /// @param _to Address to.
    /// @return reward Cake reward.
    function harvest(uint256 _tokenId, address _to) external nonReentrant returns (uint256 reward) {
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (positionInfo.liquidity == 0 && positionInfo.reward == 0) revert NoLiquidity();
        reward = harvestOperation(positionInfo, _tokenId, _to);
    }

    function harvestOperation(
        UserPositionInfo storage positionInfo,
        uint256 _tokenId,
        address _to
    ) internal returns (uint256 reward) {
        PoolInfo memory pool = poolInfo[positionInfo.pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) != address(0) && !emergency) {
            // Update rewardGrowthInside
            LMPool.accumulateReward(uint32(block.timestamp));
            uint256 rewardGrowthInside = LMPool.getRewardGrowthInside(positionInfo.tickLower, positionInfo.tickUpper);
            // Check overflow
            if (
                rewardGrowthInside > positionInfo.rewardGrowthInside &&
                MAX_U256 / (rewardGrowthInside - positionInfo.rewardGrowthInside) > positionInfo.boostLiquidity
            ) reward = ((rewardGrowthInside - positionInfo.rewardGrowthInside) * positionInfo.boostLiquidity) / Q128;
            positionInfo.rewardGrowthInside = rewardGrowthInside;
        }
        reward += positionInfo.reward;

        if (reward > 0) {
            if (_to != address(0)) {
                positionInfo.reward = 0;
                _safeTransfer(_to, reward);
                emit Harvest(msg.sender, _to, positionInfo.pid, _tokenId, reward);
            } else {
                positionInfo.reward = reward;
            }
        }
    }

    /// @notice Withdraw LP tokens from pool.
    /// @param _tokenId Token Id of NFT to deposit.
    /// @param _to Address to which NFT token to withdraw.
    /// @return reward Cake reward.
    function withdraw(uint256 _tokenId, address _to) external nonReentrant returns (uint256 reward) {
        if (_to == address(this) || _to == address(0)) revert WrongReceiver();
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        reward = harvestOperation(positionInfo, _tokenId, _to);
        uint256 pid = positionInfo.pid;
        PoolInfo storage pool = poolInfo[pid];
        ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
        if (address(LMPool) != address(0) && !emergency) {
            // Remove all liquidity from liquidity mining pool.
            int128 liquidityDelta = -int128(positionInfo.boostLiquidity);
            LMPool.updatePosition(positionInfo.tickLower, positionInfo.tickUpper, liquidityDelta);
            emit UpdateLiquidity(
                msg.sender,
                pid,
                _tokenId,
                liquidityDelta,
                positionInfo.tickLower,
                positionInfo.tickUpper
            );
        }
        pool.totalLiquidity -= positionInfo.liquidity;
        pool.totalBoostLiquidity -= positionInfo.boostLiquidity;

        delete userPositionInfos[_tokenId];
        // Update Enumerable
        removeToken(msg.sender, _tokenId);
        // Remove boosted token id in farm booster.
        if (address(FARM_BOOSTER) != address(0)) FARM_BOOSTER.removeBoostMultiplier(msg.sender, _tokenId, pid);
        nonfungiblePositionManager.safeTransferFrom(address(this), _to, _tokenId);
        emit Withdraw(msg.sender, _to, pid, _tokenId);
    }

    /// @notice Update liquidity for the NFT position.
    /// @param _tokenId Token Id of NFT to update.
    function updateLiquidity(uint256 _tokenId) external nonReentrant {
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.pid == 0) revert InvalidNFT();
        harvestOperation(positionInfo, _tokenId, address(0));
        updateLiquidityOperation(positionInfo, _tokenId, 0);
    }

    /// @notice Update farm boost multiplier for the NFT position.
    /// @param _tokenId Token Id of NFT to update.
    /// @param _newMultiplier New boost multiplier.
    function updateBoostMultiplier(uint256 _tokenId, uint256 _newMultiplier) external onlyBoostContract {
        UserPositionInfo storage positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.pid == 0) revert InvalidNFT();
        harvestOperation(positionInfo, _tokenId, address(0));
        updateLiquidityOperation(positionInfo, _tokenId, _newMultiplier);
    }

    function updateLiquidityOperation(
        UserPositionInfo storage positionInfo,
        uint256 _tokenId,
        uint256 _newMultiplier
    ) internal {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(
            _tokenId
        );
        PoolInfo storage pool = poolInfo[positionInfo.pid];
        if (positionInfo.liquidity != liquidity) {
            pool.totalLiquidity = pool.totalLiquidity - positionInfo.liquidity + liquidity;
            positionInfo.liquidity = liquidity;
        }
        uint256 boostMultiplier = BOOST_PRECISION;
        if (address(FARM_BOOSTER) != address(0) && _newMultiplier == 0) {
            // Get the latest boostMultiplier and update boostMultiplier in farm booster.
            boostMultiplier = FARM_BOOSTER.updatePositionBoostMultiplier(_tokenId);
        } else if (_newMultiplier != 0) {
            // Update boostMultiplier from farm booster call.
            boostMultiplier = _newMultiplier;
        }

        if (boostMultiplier < BOOST_PRECISION) {
            boostMultiplier = BOOST_PRECISION;
        } else if (boostMultiplier > MAX_BOOST_PRECISION) {
            boostMultiplier = MAX_BOOST_PRECISION;
        }

        positionInfo.boostMultiplier = boostMultiplier;
        uint128 boostLiquidity = ((uint256(liquidity) * boostMultiplier) / BOOST_PRECISION).toUint128();
        int128 liquidityDelta = int128(boostLiquidity) - int128(positionInfo.boostLiquidity);
        if (liquidityDelta != 0) {
            pool.totalBoostLiquidity = pool.totalBoostLiquidity - positionInfo.boostLiquidity + boostLiquidity;
            positionInfo.boostLiquidity = boostLiquidity;
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (address(LMPool) == address(0)) revert NoLMPool();
            LMPool.updatePosition(tickLower, tickUpper, liquidityDelta);
            emit UpdateLiquidity(msg.sender, positionInfo.pid, _tokenId, liquidityDelta, tickLower, tickUpper);
        }
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external payable nonReentrant returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        UserPositionInfo storage positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.pid == 0) revert InvalidNFT();
        PoolInfo memory pool = poolInfo[positionInfo.pid];
        pay(pool.token0, params.amount0Desired);
        pay(pool.token1, params.amount1Desired);
        if (pool.token0 != WETH && pool.token1 != WETH && msg.value > 0) revert();
        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity{value: msg.value}(params);
        uint256 token0Left = params.amount0Desired - amount0;
        uint256 token1Left = params.amount1Desired - amount1;
        if (token0Left > 0) {
            refund(pool.token0, token0Left);
        }
        if (token1Left > 0) {
            refund(pool.token1, token1Left);
        }
        harvestOperation(positionInfo, params.tokenId, address(0));
        updateLiquidityOperation(positionInfo, params.tokenId, 0);
    }

    /// @notice Pay.
    /// @param _token The token to pay
    /// @param _amount The amount to pay
    function pay(address _token, uint256 _amount) internal {
        if (_token == WETH && msg.value > 0) {
            if (msg.value != _amount) revert InconsistentAmount();
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /// @notice Refund.
    /// @param _token The token to refund
    /// @param _amount The amount to refund
    function refund(address _token, uint256 _amount) internal {
        if (_token == WETH && msg.value > 0) {
            nonfungiblePositionManager.refundETH();
            safeTransferETH(msg.sender, address(this).balance);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams memory params
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        UserPositionInfo storage positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        harvestOperation(positionInfo, params.tokenId, address(0));
        updateLiquidityOperation(positionInfo, params.tokenId, 0);
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// @dev Warning!!! Please make sure to use multicall to call unwrapWETH9 or sweepToken when set recipient address(0), or you will lose your funds.
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams memory params) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        UserPositionInfo memory positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (params.recipient == address(0)) params.recipient = address(this);
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient, then refund.
    /// @param params CollectParams.
    /// @param to Refund recipent.
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collectTo(
        CollectParams memory params,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        UserPositionInfo memory positionInfo = userPositionInfos[params.tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (params.recipient == address(0)) params.recipient = address(this);
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
        // Need to refund token to user when recipient is zero address
        if (params.recipient == address(this)) {
            PoolInfo memory pool = poolInfo[positionInfo.pid];
            if (to == address(0)) to = msg.sender;
            transferToken(pool.token0, to);
            transferToken(pool.token1, to);
        }
    }

    /// @notice Transfer token from MasterChef V3.
    /// @param _token The token to transfer.
    /// @param _to The to address.
    function transferToken(address _token, address _to) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        // Need to reduce cakeAmountBelongToMC.
        if (_token == address(CAKE)) {
            unchecked {
                // In fact balance should always be greater than or equal to cakeAmountBelongToMC, but in order to avoid any unknown issue, we added this check.
                if (balance >= cakeAmountBelongToMC) {
                    balance -= cakeAmountBelongToMC;
                } else {
                    // This should never happend.
                    cakeAmountBelongToMC = balance;
                    balance = 0;
                }
            }
        }
        if (balance > 0) {
            if (_token == WETH) {
                IWETH(WETH).withdraw(balance);
                safeTransferETH(_to, balance);
            } else {
                IERC20(_token).safeTransfer(_to, balance);
            }
        }
    }

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external nonReentrant {
        uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
        if (balanceWETH < amountMinimum) revert InsufficientAmount();

        if (balanceWETH > 0) {
            IWETH(WETH).withdraw(balanceWETH);
            safeTransferETH(recipient, balanceWETH);
        }
    }

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(address token, uint256 amountMinimum, address recipient) external nonReentrant {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        // Need to reduce cakeAmountBelongToMC.
        if (token == address(CAKE)) {
            unchecked {
                // In fact balance should always be greater than or equal to cakeAmountBelongToMC, but in order to avoid any unknown issue, we added this check.
                if (balanceToken >= cakeAmountBelongToMC) {
                    balanceToken -= cakeAmountBelongToMC;
                } else {
                    // This should never happend.
                    cakeAmountBelongToMC = balanceToken;
                    balanceToken = 0;
                }
            }
        }
        if (balanceToken < amountMinimum) revert InsufficientAmount();

        if (balanceToken > 0) {
            IERC20(token).safeTransfer(recipient, balanceToken);
        }
    }

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param _tokenId The ID of the token that is being burned
    function burn(uint256 _tokenId) external nonReentrant {
        UserPositionInfo memory positionInfo = userPositionInfos[_tokenId];
        if (positionInfo.user != msg.sender) revert NotOwner();
        if (positionInfo.reward > 0 || positionInfo.liquidity > 0) revert NotEmpty();
        delete userPositionInfos[_tokenId];
        // Update Enumerable
        removeToken(msg.sender, _tokenId);
        // Remove boosted token id in farm booster.
        if (address(FARM_BOOSTER) != address(0))
            FARM_BOOSTER.removeBoostMultiplier(msg.sender, _tokenId, positionInfo.pid);
        nonfungiblePositionManager.burn(_tokenId);
        emit Withdraw(msg.sender, address(0), positionInfo.pid, _tokenId);
    }

    /// @notice Upkeep period.
    /// @param _amount The amount of cake injected.
    /// @param _duration The period duration.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function upkeep(uint256 _amount, uint256 _duration, bool _withUpdate) external onlyReceiver {
        // Transfer cake token from receiver.
        CAKE.safeTransferFrom(receiver, address(this), _amount);
        // Update cakeAmountBelongToMC
        unchecked {
            cakeAmountBelongToMC += _amount;
        }

        if (_withUpdate) massUpdatePools();

        uint256 duration = PERIOD_DURATION;
        // Only use the _duration when _duration is between MIN_DURATION and MAX_DURATION.
        if (_duration >= MIN_DURATION && _duration <= MAX_DURATION) duration = _duration;
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + duration;
        uint256 cakePerSecond;
        uint256 cakeAmount = _amount;
        if (latestPeriodEndTime > currentTime) {
            uint256 remainingCake = ((latestPeriodEndTime - currentTime) * latestPeriodCakePerSecond) / PRECISION;
            emit UpdateUpkeepPeriod(latestPeriodNumber, latestPeriodEndTime, currentTime, remainingCake);
            cakeAmount += remainingCake;
        }
        cakePerSecond = (cakeAmount * PRECISION) / duration;
        unchecked {
            latestPeriodNumber++;
            latestPeriodStartTime = currentTime + 1;
            latestPeriodEndTime = endTime;
            latestPeriodCakePerSecond = cakePerSecond;
        }
        emit NewUpkeepPeriod(latestPeriodNumber, currentTime + 1, endTime, cakePerSecond, cakeAmount);
    }

    /// @notice Update cake reward for all the liquidity mining pool.
    function massUpdatePools() internal {
        uint32 currentTime = uint32(block.timestamp);
        for (uint256 pid = 1; pid <= poolLength; pid++) {
            PoolInfo memory pool = poolInfo[pid];
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (pool.allocPoint != 0 && address(LMPool) != address(0)) {
                LMPool.accumulateReward(currentTime);
            }
        }
    }

    /// @notice Update cake reward for the liquidity mining pool.
    /// @dev Avoid too many pools, and a single transaction cannot be fully executed for all pools.
    function updatePools(uint256[] calldata pids) external onlyOwnerOrOperator {
        uint32 currentTime = uint32(block.timestamp);
        for (uint256 i = 0; i < pids.length; i++) {
            PoolInfo memory pool = poolInfo[pids[i]];
            ILMPool LMPool = ILMPool(pool.v3Pool.lmPool());
            if (pool.allocPoint != 0 && address(LMPool) != address(0)) {
                LMPool.accumulateReward(currentTime);
            }
        }
    }

    /// @notice Set operator address.
    /// @dev Callable by owner
    /// @param _operatorAddress New operator address.
    function setOperator(address _operatorAddress) external onlyOwner {
        if (_operatorAddress == address(0)) revert ZeroAddress();
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(_operatorAddress);
    }

    /// @notice Set period duration.
    /// @dev Callable by owner
    /// @param _periodDuration New period duration.
    function setPeriodDuration(uint256 _periodDuration) external onlyOwner {
        if (_periodDuration < MIN_DURATION || _periodDuration > MAX_DURATION) revert InvalidPeriodDuration();
        PERIOD_DURATION = _periodDuration;
        emit NewPeriodDuration(_periodDuration);
    }

    /// @notice Update farm boost contract address.
    /// @param _newFarmBoostContract The new farm booster address.
    function updateFarmBoostContract(address _newFarmBoostContract) external onlyOwner {
        // farm booster can be zero address when need to remove farm booster
        FARM_BOOSTER = IFarmBooster(_newFarmBoostContract);
        emit UpdateFarmBoostContract(_newFarmBoostContract);
    }

    /**
     * @notice Transfer ETH in a safe way
     * @param to: address to transfer ETH to
     * @param value: ETH amount to transfer (in wei)
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) revert();
    }

    /// @notice Safe Transfer CAKE.
    /// @param _to The CAKE receiver address.
    /// @param _amount Transfer CAKE amounts.
    function _safeTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            uint256 balance = CAKE.balanceOf(address(this));
            if (balance < _amount) {
                _amount = balance;
            }
            // Update cakeAmountBelongToMC
            unchecked {
                if (cakeAmountBelongToMC >= _amount) {
                    cakeAmountBelongToMC -= _amount;
                } else {
                    cakeAmountBelongToMC = balance - _amount;
                }
            }
            CAKE.safeTransfer(_to, _amount);
        }
    }

    receive() external payable {
        if (msg.sender != address(nonfungiblePositionManager) && msg.sender != WETH) revert();
    }
}