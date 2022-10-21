pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-periphery/contracts/libraries/PositionKey.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import '@uniswap/v3-core/contracts/libraries/FixedPoint128.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';

import './base/PoolManagement.sol';
import './base/Multicall.sol';

contract JITPositionManager is Ownable, PoolManagement, Multicall {
    event RelayerRole(address relayer, bool newStatus);

    // details about the uniswap position
    struct Position {
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
    }

    mapping(address => bool) public isRelayer;
    address[] public relayers;

    mapping(address => uint80) private _poolIds;
    mapping(uint80 => PoolAddress.PoolKey) private _poolIdToPoolKey;

    Position public currentPosition;
    uint80 private _nextPoolId = 1;

    modifier checkDeadline(uint256 deadline) {
        require(uint32(block.timestamp) <= deadline, 'Transaction too old');
        _;
    }

    modifier onlyRelayerOrOwner() {
        require(msg.sender ==  owner()|| isRelayer[msg.sender], "Only relayer or owner");
        _;
    }

    constructor(address _uniswapFactory) PoolManagement(_uniswapFactory) {
        // 
    }

    function cachePool(address tokenA, address tokenB, uint24 fee) external {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee});
        address poolAddress = PoolAddress.computeAddress(uniswapFactory, poolKey);

        cachePoolKey(poolAddress, poolKey);
    }

    function grantRelayerRole(address newRelayer) onlyOwner external payable {
        isRelayer[newRelayer] = true;
        emit RelayerRole(newRelayer, true);
    }

    function revokeRelayerRole(address relayer) onlyOwner external payable {
        isRelayer[relayer] = false;
        emit RelayerRole(relayer, false);
    }

    function withdraw(address token, uint256 amount) onlyOwner external payable {
        if (token == address(0)) payable(msg.sender).transfer(amount);
        else TransferHelper.safeTransfer(token, msg.sender, amount);
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        checkDeadline(params.deadline)
        onlyRelayerOrOwner
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(currentPosition.liquidity == 0, 'not burned');

        IUniswapV3Pool pool;
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min
            })
        );
        require(liquidity > 0, 'insufficient liquidity');

        uint80 poolId =
            cachePoolKey(
                address(pool),
                PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee})
            );

        currentPosition = Position({
            poolId: poolId,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity
        });
    }

    function burn(
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        onlyRelayerOrOwner
        returns (uint256 amount0, uint256 amount1)
    {
        // single SLOAD
        (uint128 liquidity, int24 tickLower, int24 tickUpper, uint80 poolId) = (currentPosition.liquidity, currentPosition.tickLower, currentPosition.tickUpper, currentPosition.poolId);

        require(liquidity > 0, 'not minted');

        // burn liquidity and update fees
        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[poolId];
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(uniswapFactory, poolKey));
        (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidity);
        require(amount0 >= amount0Min && amount1 >= amount1Min, 'Price slippage check');

        // pull tokens
        pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);

        delete currentPosition;
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function swapExactInputSingle(ExactInputSingleParams calldata params) 
    external 
    payable
    checkDeadline(params.deadline) 
    onlyRelayerOrOwner 
    returns(uint256 amountOut) {

       amountOut = swapExactInputSingleInternal(
        params.tokenIn,
        params.tokenOut,
        params.fee,
        params.amountIn,
        params.sqrtPriceLimitX96
       );

       require(amountOut >= params.amountOutMinimum, 'slippage check failed');
    }
    
    function cachePoolKey(address pool, PoolAddress.PoolKey memory poolKey) private returns (uint80 poolId) {
        poolId = _poolIds[pool];
        if (poolId == 0) {
            _poolIds[pool] = (poolId = _nextPoolId++);
            _poolIdToPoolKey[poolId] = poolKey;
        }
    }
}