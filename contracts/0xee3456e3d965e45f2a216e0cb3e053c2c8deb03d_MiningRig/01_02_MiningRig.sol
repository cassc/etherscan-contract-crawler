// SPDX-License-Identifier: MIT
// Shipped as BUSL-1.1 License 
// Credits to 0xPauly, Pond0x, Pond Coin, and Pond D🤝X
pragma solidity ^0.8.17;

import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";

contract MiningRig {

    uint256 public PID; 

    address private immutable WETH;
    address private immutable PPEPE;
    address private immutable PEPE;
    address private immutable COSMIC_DISTILLERY;

    INonfungiblePositionManager private immutable nonfungiblePositionManager;

    struct Mining {
        uint blockno;
        uint256 mined;
        uint256 totalMinedPositions;
        uint256 difficulty;
        uint256 virtualWeight;
        uint256 vPool;
    }

    struct MiningRewards {
        uint256 base;
        uint256 balance;
        uint256 frequency;
        uint256 held;
        uint256 debt;
        uint256 redeemable;
    }

    mapping(address => MiningRewards) public scores;

    Mining public rig;

    constructor(
        INonfungiblePositionManager _nonfungiblePositionManager,
        address _ppepe,
        address _pepe,
        address _weth,
        address _cosmic_distillery
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        PPEPE = _ppepe;
        PEPE = _pepe;
        WETH = _weth;
        COSMIC_DISTILLERY = _cosmic_distillery;
        SafeTransferLib.safeApprove(WETH, address(_nonfungiblePositionManager), type(uint256).max);
    }

    function mineLiquidity(uint256 amountOutMinUniswap) payable external returns(uint128, uint newAllot, uint256 quote) {
        require(msg.value != 0, "NONZERO");
        if (rig.totalMinedPositions <= 1000) require(msg.value <= 5 ether, "UNFAIR");
        uint256 swappedAmtOut = _hopOnUniswap(amountOutMinUniswap);
        (uint128 liquidity, uint128 vliquidity ) = _addLiquidity(swappedAmtOut);
        uint256 _totalLiquidity = uint256(liquidity);
        uint256 _xt = _totalLiquidity + (_totalLiquidity+uint256(vliquidity));
        quote = (_totalLiquidity * 4) + (swappedAmtOut * 8);
        MINEABLE(PPEPE).mintSupplyFromMinedLP(msg.sender, quote);
        if (scores[msg.sender].base == 0 && rig.blockno <= 9 ) scores[msg.sender].redeemable =  rig.blockno + 1;
        scores[msg.sender].base += _xt + (_totalLiquidity * rig.difficulty);
        scores[msg.sender].balance = IERC20(PPEPE).balanceOf(msg.sender);
        ++scores[msg.sender].frequency;
        scores[msg.sender].held = IERC20(PEPE).balanceOf(msg.sender);
        newAllot = _calculate(msg.sender);
        scores[msg.sender].debt += newAllot;
        rig.mined += newAllot;
        if (rig.difficulty != 0){  --rig.difficulty; }
        rig.vPool += swappedAmtOut;
        ++rig.totalMinedPositions;
        return (liquidity, newAllot, quote);
    }  

    function _calculate(address _address) internal view returns(uint) {
        uint256 _alloc = scores[_address].base;
        _alloc += 1 << scores[_address].frequency;
        _alloc += scores[_address].held;
        _alloc += scores[_address].balance;
        return _alloc;
    }

    function score(address _address) external view returns(uint) {
        require(scores[_address].base != 0, "COPE");
        return _calculate(_address);
    }

    function _hopOnUniswap(
        uint256 amountOutMin
    ) internal returns (uint amountOut) {
        amountOut = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564).exactInputSingle{value: msg.value >> 1}(
        ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: PEPE,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountIn: msg.value >> 1,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        })
        );
        return amountOut;
    }
    function _addLiquidity(
        uint256 amountIn
    ) internal returns (uint128 liquidity, uint128 vliquidity) {
        IWETH(WETH).deposit{ value: msg.value >> 1 }();
        IERC20(PEPE).approve(address(nonfungiblePositionManager), type(uint256).max);
        IWETH(WETH).approve(address(nonfungiblePositionManager), type(uint256).max);
        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: PID,
            amount0Desired: amountIn / rig.virtualWeight,
            amount1Desired: (msg.value >> 1) / rig.virtualWeight,
            amount0Min: 0,
            amount1Min: 0,
            deadline:  block.timestamp + 300
        });
        uint256 amount0;
        uint256 amount1;
        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
        return (liquidity,  uint128(liquidity * uint128(rig.virtualWeight)) - liquidity);
    }
    function bootUp(uint256 amountOutMinUniswap ) payable external returns(uint256 lpTokenId, uint256 liquidity, uint amount0, uint amount1 ) {
        require(msg.value != 0, "Must pass non 0 ETH amount");
        require(rig.virtualWeight == 0, "Set");
        uint256 swappedAmtOut = _hopOnUniswap(amountOutMinUniswap);
        rig.difficulty = 1000;
        rig.virtualWeight = 16;
        (lpTokenId, liquidity, amount0, amount1) = _bootLiquidityPosition(swappedAmtOut, msg.value >> 1, 60, -211140, -210120);
        MINEABLE(PPEPE).activate();
        PID = lpTokenId;
        return (liquidity, lpTokenId, amount0, amount1);
    }  

    function _bootLiquidityPosition(
        uint amount0ToAdd,
        uint amount1ToAdd,
        int24 tickspacing,
        int24 mintick,
        int24 maxtick
    ) internal returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        IWETH(WETH).deposit{ value: msg.value >> 1 }();
        IERC20(PEPE).approve(address(nonfungiblePositionManager), amount0ToAdd);
        IWETH(WETH).approve(address(nonfungiblePositionManager), amount1ToAdd);
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: PEPE,
                token1: WETH,
                fee: 3000,
                tickLower: (mintick / tickspacing) * tickspacing,
                tickUpper: (maxtick / tickspacing) * tickspacing,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );
        return (tokenId, liquidity, amount0, amount1);
    }
    
    receive() external payable {}

    function sqrt96Tick(
        uint24 _fee, 
        address _factory,
        address _token
    ) internal view returns (uint, int24) {
        (address _pool) = IUniswapV3Factory(_factory).getPool(_token, WETH, _fee);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = IUniswapV3Pool(_pool).slot0();
        return ((uint(sqrtPriceX96) ** 2) * (1**18) / (192**2), tick);
    }

    function deltaNeutralLPContinuum(
        address _factory,
        uint128 _liquidity,
        uint amountOutMinUniswap,
        uint256 _virtualWeight, 
        int24 _delta,
        uint24 _fee
    ) external payable returns(uint tokenId, uint128 liquidity ) {
            require(msg.value > 1 ether, "FEE");
            (, int24 tick) = sqrt96Tick(_fee, _factory, PEPE);
            _collectLpFees(PID);
            uint256 swappedAmtOut = _hopOnUniswap(amountOutMinUniswap);
            int24 TICK_SPACING = 60;
            IWETH(WETH).deposit{ value: msg.value >> 1 }();
            IERC20(PEPE).approve(address(nonfungiblePositionManager), swappedAmtOut);
            IWETH(WETH).approve(address(nonfungiblePositionManager), msg.value >> 1);
            INonfungiblePositionManager.MintParams
                memory params = INonfungiblePositionManager.MintParams({
                    token0: PEPE,
                    token1: WETH,
                    fee: _fee,
                    tickLower: ((tick - _delta) / TICK_SPACING) * TICK_SPACING,
                    tickUpper: ((tick + _delta) / TICK_SPACING) * TICK_SPACING,
                    amount0Desired: swappedAmtOut,
                    amount1Desired: msg.value >> 1,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp + 300
                });
            (tokenId, liquidity, , ) = nonfungiblePositionManager.mint(
                params
            );
            _produceLevelsFromPools(_liquidity, PID);
            _observeVirtualPoolCardinality();
            PID = tokenId;
            rig.virtualWeight = _virtualWeight;
            _convertWETHforETH();
            return (tokenId, liquidity);
    }

    function precision(uint a, uint b, uint _precision) internal pure returns ( uint) {
     return a*(10**_precision)/b;
    }
    function calculateBlock() internal view returns (uint) {
        uint256 _supply = IERC20(PPEPE).totalSupply();
        uint256 _complete = precision(_supply, 100000000000000000000000000000000, 1);
        return _complete;
    }

    function finalizeBlock(
        uint128 liquidity,
        uint256 tokenId
    ) external returns(uint){
        uint256 _block = calculateBlock();
        require(_block != rig.blockno, 'UNMET');
        _produceLevelsFromPools(liquidity, tokenId);
        rig.blockno = uint(_block);
        _observeVirtualPoolCardinality();
        return _block;
    }

    function bribeForLevelReward() external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1){
        require(msg.value > 0.25 ether, "NONZERO");
        uint256 _block = calculateBlock();
        (,,,,,,,liquidity,,,,) = nonfungiblePositionManager.positions(PID);
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: PID,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        _observeVirtualPoolCardinality();
        _convertWETHforETH();
        rig.blockno = uint(_block);
        return (liquidity, amount0, amount1);
    }
    function _observeVirtualPoolCardinality() internal returns (uint){
        SafeTransferLib.safeTransferETH(address(COSMIC_DISTILLERY), address(this).balance);
        uint256 _pepeBalance = IERC20(PEPE).balanceOf(address(this));
        SafeTransferLib.safeApprove(PEPE, address(COSMIC_DISTILLERY), type(uint256).max);
        SafeTransferLib.safeTransfer(PEPE,  address(COSMIC_DISTILLERY), _pepeBalance >> 1);
        return _pepeBalance;
    }
    function _convertWETHforETH() internal returns (bool){
        IWETH(WETH).withdraw(IWETH(WETH).balanceOf(address(this)));
        SafeTransferLib.safeTransferETH(address(COSMIC_DISTILLERY), address(this).balance);
        return true;
    }
    function _produceLevelsFromPools(
        uint128 liquidity,
        uint256 tokenId
    ) internal returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        return (amount0, amount1);
    }
    function _collectLpFees (uint256 tokenId) internal returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }
    function unifee(uint256 tokenId) external payable returns (uint amount0, uint amount1) {
       (amount0, amount1) = _collectLpFees(tokenId);
    }
    function locked() external payable returns (uint){
        require(rig.blockno >= 9, "LOCKED");
        require(msg.value > 0.25 ether, "NONZERO");
        _collectLpFees(PID);
        _observeVirtualPoolCardinality();
        _convertWETHforETH();
        return PID;
    }
 
}

interface IUniswapV3Factory {
     function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

interface IUniswapV3Pool is
    IUniswapV3PoolState
{}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
    );

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

}
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);
}

interface MINEABLE { 
    function mintSupplyFromMinedLP(address miner, uint256 value) external; 
    function activate() external;
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}