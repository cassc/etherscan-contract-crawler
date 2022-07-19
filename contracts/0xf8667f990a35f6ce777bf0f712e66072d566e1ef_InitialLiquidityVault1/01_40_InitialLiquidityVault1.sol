//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// import "../interfaces/IUniswapV3Factory.sol";
// import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/INonfungiblePositionManager.sol";
import "../interfaces/IInitialLiquidityVaultEvent1.sol";
import "../interfaces/IInitialLiquidityVaultAction1.sol";
import "../interfaces/IEventLog.sol";

import "../libraries/TickMath.sol";
import "../libraries/OracleLibrary.sol";
import '../libraries/FixedPoint96.sol';
import '../libraries/FullMath.sol';

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./InitialLiquidityVaultStorage.sol";

import "../proxy/VaultStorage.sol";
import "../common/ProxyAccessCommon.sol";
import "./InitialLiquidityVaultStorage1.sol";
// import "hardhat/console.sol";

interface I2ERC20 {
    function decimals() external view returns (uint256);
}

interface IIUniswapV3Pool {

    function token0() external view returns (address);
    function token1() external view returns (address);

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

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);


}

contract InitialLiquidityVault1 is
    InitialLiquidityVaultStorage,
    VaultStorage,
    ProxyAccessCommon,
    IInitialLiquidityVaultEvent1,
    IInitialLiquidityVaultAction1,
    InitialLiquidityVaultStorage1
{
    using SafeERC20 for IERC20;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Vault: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "Vault: zero value");
        _;
    }

    modifier readyToCreatePool() {
        require(boolReadyToCreatePool, "Vault: not ready to CreatePool");
        _;
    }

    modifier beforeSetReadyToCreatePool() {
        require(!boolReadyToCreatePool, "Vault: already ready to CreatePool");
        _;
    }

    modifier afterSetUniswap() {
        require(
            address(UniswapV3Factory) != address(0)
            && address(NonfungiblePositionManager) != address(0)
            && address(TOS) != address(0)
            ,
            "Vault: before setUniswap");
        _;
    }

    ///@dev constructor
    constructor() {
    }

    function setStartTime(uint256 _startTime) public override onlyOwner
    {
        require(_startTime > block.timestamp, "StartTime has passed");
        require(startTime != _startTime, "same StartTime");
        startTime = _startTime;
        emit SetStartTime(_startTime);
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 tosPrice,
        uint256 tokenPrice,
        uint160 initSqrtPrice,
        uint256 _startTime
    )
        external override onlyOwner afterSetUniswap
    {
        require(initSqrtPriceX96 == 0, "already initialized");
        require(_totalAllocatedAmount <= token.balanceOf(address(this)), "need to input the token");
        require(tosPrice > 0 && tokenPrice > 0 && initSqrtPrice > 0,
            "zero tosPrice or tokenPrice or initSqrtPriceX96 or startTime");

        totalAllocatedAmount = _totalAllocatedAmount;

        initialTosPrice = tosPrice;
        initialTokenPrice = tokenPrice;
        initSqrtPriceX96 = initSqrtPrice;
        setStartTime(_startTime);

        emit Initialized(_totalAllocatedAmount);
        emit SetInitialPrice(tosPrice, tokenPrice, initSqrtPrice);
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function setUniswapInfo(
        address poolfactory,
        address npm
        )
        external override
        onlyProxyOwner
    {
        require(poolfactory != address(0) && poolfactory != address(UniswapV3Factory), "zero or same UniswapV3Factory");
        require(npm != address(0) && npm != address(NonfungiblePositionManager), "zero or same npm");

        UniswapV3Factory = IUniswapV3Factory(poolfactory);
        NonfungiblePositionManager = INonfungiblePositionManager(npm);

        emit SetUniswapInfo(poolfactory, npm);
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function setTokens(
            address tos,
            uint24 _fee
        )
        external override
        onlyProxyOwner beforeSetReadyToCreatePool
    {
        require(tos != address(0) && tos != address(TOS), "same tos");

        TOS = IERC20(tos);
        fee = _fee;

        if(fee == 500) tickSpacings = 10;
        else if(fee == 3000) tickSpacings = 60;
        else if(fee == 10000) tickSpacings = 200;

        emit SetTokens(tos, _fee, tickSpacings);
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function setCreatePool() external override beforeSetReadyToCreatePool
    {
        require(initSqrtPriceX96 > 0, "zero initSqrtPriceX96");

        setPool();

        address getPool = UniswapV3Factory.getPool(address(TOS), address(token), fee);
        require(getPool == address(pool), "different pool address");
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        require(sqrtPriceX96 > 0, "price is zero");
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function setPool()
        public override afterSetUniswap beforeSetReadyToCreatePool
    {
        require(startTime > 0 && startTime < block.timestamp, "StartTime has not passed.");
        address getPool = UniswapV3Factory.getPool(address(TOS), address(token), fee);
        if(getPool == address(0)){
            address _pool = UniswapV3Factory.createPool(address(TOS), address(token), fee);
            require(_pool != address(0), "createPool fail");
            getPool = _pool;
        }
        pool = IUniswapV3Pool(getPool);
        token0Address = pool.token0();
        token1Address = pool.token1();

        boolReadyToCreatePool = true;

        if(initSqrtPriceX96 > 0){
            setPoolInitialize(initSqrtPriceX96);
        }

        emit SetPool(address(pool), token0Address, token1Address);
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function setPoolInitialize(uint160 inSqrtPriceX96)
        public nonZeroAddress(address(pool)) override readyToCreatePool
    {
        require(inSqrtPriceX96 > 0, "zero inSqrtPriceX96");
        (uint160 sqrtPriceX96,,,,uint16 observationCardinalityNext,,) =  pool.slot0();
        if(sqrtPriceX96 == 0){
            pool.initialize(inSqrtPriceX96);

            emit SetPoolInitialized(inSqrtPriceX96);
        }

        if (observationCardinalityNext < 8) {
            pool.increaseObservationCardinalityNext(8);
        }
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function computePoolAddress(address tokenA, address tokenB, uint24 _fee)
        public view override returns (address pool, address token0, address token1)
    {
        bytes32  POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

        token0 = tokenA;
        token1 = tokenB;

        if(token0 > token1) {
            token0 = tokenB;
            token1 = tokenA;
        }

        pool = address( uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        address(UniswapV3Factory),
                        keccak256(abi.encode(token0, token1, _fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            ))
        );
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function getMinTick() public view override returns (int24){
           return (TickMath.MIN_TICK / tickSpacings) * tickSpacings ;
    }

    /// @inheritdoc IInitialLiquidityVaultAction1
    function getMaxTick() public view override  returns (int24){
           return (TickMath.MAX_TICK / tickSpacings) * tickSpacings ;
    }

    function getSqrtRatioAtTick(int24 tick) public pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) public pure  returns (int24) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    function checkBalance(uint256 tosBalance, uint256 tokenBalance) internal  {
        require(TOS.balanceOf(address(this)) >= tosBalance, "tos is insufficient.");
        require(token.balanceOf(address(this)) >= tokenBalance, "token is insufficient.");
         if(tosBalance > TOS.allowance(address(this), address(NonfungiblePositionManager)) ) {
                require(TOS.approve(address(NonfungiblePositionManager),TOS.totalSupply()),"TOS approve fail");
        }

        if(tokenBalance > token.allowance(address(this), address(NonfungiblePositionManager)) ) {
            require(token.approve(address(NonfungiblePositionManager),token.totalSupply()),"token approve fail");
        }
    }

    function setAcceptTickChangeInterval(int24 _interval) external onlyOwner
    {
        require(_interval > 0, "zero");
        require(acceptTickChangeInterval != _interval, "same");
        acceptTickChangeInterval = _interval;
    }

    function setAcceptSlippagePrice(int24 _value) external onlyOwner
    {
        require(_value > 0, "zero");
        require(acceptSlippagePrice != _value, "same");
        acceptSlippagePrice = _value;
    }

    function setTWAP_PERIOD(uint32 value) external onlyOwner
    {
        require(value > 0, "zero");
        require(TWAP_PERIOD != value, "same");
        TWAP_PERIOD = value;
    }

    function mint(uint256 tosAmount)
        external override readyToCreatePool nonReentrant
        nonZeroAddress(address(pool))
        nonZeroAddress(token0Address)
        nonZeroAddress(token1Address)
    {
        require(tosAmount > 0, "zero input amount");
        uint256 tosBalance =  TOS.balanceOf(address(this));
        uint256 tokenBalance =  token.balanceOf(address(this));
        require(tosBalance > 1 ether && tokenBalance > 1 ether, "balance is insufficient");
        require(tosAmount <= tosBalance, "toBalance is insufficient");

        if (acceptTickChangeInterval == 0) acceptTickChangeInterval = 8;
        if (acceptSlippagePrice == 0) acceptSlippagePrice = 10; // based 100
        if (TWAP_PERIOD == 0) TWAP_PERIOD = 120;

        (uint160 sqrtPriceX96, int24 tick,,,,,) =  pool.slot0();
        require(sqrtPriceX96 > 0, "pool is not initialized");

        //if (lpToken > 0)
        {
            int24 timeWeightedAverageTick = OracleLibrary.consult(address(pool), TWAP_PERIOD);
            require(
                acceptMinTick(timeWeightedAverageTick, getTickSpacing(fee)) <= tick
                && tick < acceptMaxTick(timeWeightedAverageTick, getTickSpacing(fee)),
                "It's not allowed changed tick range."
            );
        }

        uint256 amount0Desired = 0;
        uint256 amount1Desired = 0;

        if(token0Address != address(TOS)){
            amount0Desired = getQuoteAtTick(
                tick,
                uint128(tosAmount),
                address(TOS),
                address(token)
                );
            amount1Desired = tosAmount;

            require(amount0Desired <= tokenBalance, "tokenBalance is insufficient");
            checkBalance(amount1Desired, amount0Desired);
        } else {
            amount0Desired = tosAmount;
            amount1Desired = getQuoteAtTick(
                tick,
                uint128(tosAmount),
                address(TOS),
                address(token)
                );

            require(amount1Desired <= tokenBalance, "tokenBalance is insufficient");
            checkBalance(amount0Desired, amount1Desired);
        }

        uint256 amount0Min = amount0Desired * (100 - uint256(int256(acceptSlippagePrice))) / 100;
        uint256 amount1Min = amount1Desired * (100 - uint256(int256(acceptSlippagePrice))) / 100;

        if(lpToken == 0)  initialMint(amount0Desired, amount1Desired, amount0Min, amount1Min);
        else increaseLiquidity(amount0Desired, amount1Desired, amount0Min, amount1Min);
    }

    function initialMint(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min) internal
    {
        require(lpToken == 0, "already minted");

        int24 tickLower = getMinTick();
        int24 tickUpper = getMaxTick();

        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = NonfungiblePositionManager.mint(INonfungiblePositionManager.MintParams(
                token0Address, token1Address, fee, tickLower, tickUpper,
                amount0Desired, amount1Desired, amount0Min, amount1Min,
                address(this), block.timestamp + 100
            )
        );

        require(tokenId > 0, "tokenId is zero");

        lpToken = tokenId;

        emit MintedInVault(msg.sender, tokenId, liquidity, amount0, amount1);
    }

    function increaseLiquidity(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min) internal
    {
        require(lpToken > 0, "It is not minted yet");

        (uint128 liquidity, uint256 amount0, uint256 amount1) = NonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(
                lpToken, amount0Desired, amount1Desired, amount0Min, amount1Min, block.timestamp + 100 ));

        emit IncreaseLiquidityInVault(lpToken, liquidity, amount0, amount1);
    }


    /// @inheritdoc IInitialLiquidityVaultAction1
    function collect()
        external override
        nonZeroAddress(address(pool))
        nonReentrant
    {
        require(lpToken > 0, "It is not minted yet");
        (,,,,,,,,,,uint128 tokensOwed0, uint128 tokensOwed1) = NonfungiblePositionManager.positions(lpToken);
        require(tokensOwed0 > 0 || tokensOwed1 > 0, "there is no collectable amount");

        (
            uint256 amount0,
            uint256 amount1
        ) = NonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(
                lpToken, address(this), tokensOwed0, tokensOwed1
            )
        );

        emit CollectInVault(lpToken, amount0, amount1);
    }


    function getPriceToken0(address poolAddress) public view returns (uint256 priceX96) {

        (, int24 tick, , , , ,) = IIUniswapV3Pool(poolAddress).slot0();
        (uint256 token0Decimals, ) = getDecimals(
            IIUniswapV3Pool(poolAddress).token0(),
            IIUniswapV3Pool(poolAddress).token1()
            );

        priceX96 = OracleLibrary.getQuoteAtTick(
             tick,
             uint128(10**token0Decimals),
             IIUniswapV3Pool(poolAddress).token0(),
             IIUniswapV3Pool(poolAddress).token1()
             );
    }

    function getPriceToken1(address poolAddress) public view returns(uint256 priceX96) {

        (, int24 tick, , , , ,) = IIUniswapV3Pool(poolAddress).slot0();
        (, uint256 token1Decimals) = getDecimals(
            IIUniswapV3Pool(poolAddress).token0(),
            IIUniswapV3Pool(poolAddress).token1()
            );

        priceX96 = OracleLibrary.getQuoteAtTick(
             tick,
             uint128(10**token1Decimals),
             IIUniswapV3Pool(poolAddress).token1(),
             IIUniswapV3Pool(poolAddress).token0()
             );
    }

    function getDecimals(address token0, address token1) public view returns(uint256 token0Decimals, uint256 token1Decimals) {
        return (I2ERC20(token0).decimals(), I2ERC20(token1).decimals());
    }

    function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) public pure returns(uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function currentTick() public view returns(uint160 sqrtPriceX96, int24 tick) {

        if(address(pool) == address(0)){
            address getPool = UniswapV3Factory.getPool(address(TOS), address(token), fee);
            if(getPool != address(0)) {
                (uint160 sqrtPriceX961, int24 tick1,,,,,) =  IUniswapV3Pool(getPool).slot0();
                return (sqrtPriceX961, tick1);
            }
            return (0, 0);
        }

        (sqrtPriceX96,tick,,,,,) =  pool.slot0();
    }

    function getTickSpacing(uint24 _fee) public pure returns (int24 tickSpacings)
    {
        if(_fee == 500) tickSpacings = 10;
        else if(_fee == 3000) tickSpacings = 60;
        else if(_fee == 10000) tickSpacings = 200;
    }

    function acceptMinTick(int24 _tick, int24 _tickSpacings) public view returns (int24)
    {
        int24 _minTick = getMiniTick(_tickSpacings);
        int24 _acceptMinTick = _tick - (_tickSpacings * int24(uint24(acceptTickChangeInterval)));

        if(_minTick < _acceptMinTick) return _acceptMinTick;
        else return _minTick;
    }

    function acceptMaxTick(int24 _tick, int24 _tickSpacings) public view returns (int24)
    {
        int24 _maxTick = getMaxTick(_tickSpacings);
        int24 _acceptMinTick = _tick + (_tickSpacings * int24(uint24(acceptTickChangeInterval)));

        if(_maxTick < _acceptMinTick) return _maxTick;
        else return _acceptMinTick;
    }

    function getMiniTick(int24 tickSpacings) public pure returns (int24){
           return (TickMath.MIN_TICK / tickSpacings) * tickSpacings ;
    }

    function getMaxTick(int24 tickSpacings) public pure  returns (int24){
           return (TickMath.MAX_TICK / tickSpacings) * tickSpacings ;
    }

    function getQuoteAtTick(
        int24 tick,
        uint128 amountIn,
        address baseToken,
        address quoteToken
    ) public pure returns (uint256 amountOut) {
        return OracleLibrary.getQuoteAtTick(tick, amountIn, baseToken, quoteToken);
    }

}