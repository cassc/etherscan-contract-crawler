// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./libraries/TickMath.sol";
import "./libraries/LiquidityAmounts.sol";
import "./libraries/OracleLibrary.sol";
import "./libraries/FixedPoint128.sol";
import "./libraries/PositionKey.sol";
import "./libraries/SafeMath512.sol";

import "./interfaces/ITOSValueCalculator.sol";

// import "hardhat/console.sol";

interface IERC20 {
    function decimals() external  view returns (uint256);
}

interface IIUniswapV3Factory {
    function getPool(address,address,uint24) external view returns (address);
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

interface IINonfungiblePositionManager {
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
}

contract TOSValueCalculator is ITOSValueCalculator {

    IIUniswapV3Factory public UniswapV3Factory;
    address public tos;
    address public weth;
    address public npm_;
    address public ethTosPool;

    /// @inheritdoc ITOSValueCalculator
    function initialize(
        address _tos,
        address _weth,
        address _npm,
        address _basicPool,
        address _uniswapV3Factory
    )
        external
        override
    {
        require(tos == address(0), "already initialized");
        tos = _tos;
        weth = _weth;
        npm_ = _npm;
        ethTosPool = _basicPool;
        UniswapV3Factory = IIUniswapV3Factory(_uniswapV3Factory);
    }


    /// @inheritdoc ITOSValueCalculator
    function getWETHPoolTOSPrice() public override view returns (uint256 price) {
        uint tosOrder = getTOStoken0(weth, 3000);

        if(tosOrder == 0) {
            price = getPriceToken0(ethTosPool);
        } else if (tosOrder == 1) {
            price = getPriceToken1(ethTosPool);
        }
    }

    /// @inheritdoc ITOSValueCalculator
    function getTOStoken0(address _erc20Addresss, uint24 _fee) public override view returns (uint) {
        address getPool = UniswapV3Factory.getPool(address(tos), address(_erc20Addresss), _fee);
        if(getPool == address(0)) {
            return 2;
        }
        // pool = IUniswapV3Pool(getPool);
        address token0Address = IIUniswapV3Pool(getPool).token0();
        address token1Address = IIUniswapV3Pool(getPool).token1();
        if(token0Address == address(tos)) {
           return 0;
        } else if(token1Address == address(tos)) {
            return 1;
        } else {
            return 3;
        }
    }

    /// @inheritdoc ITOSValueCalculator
    function getTOStoken(address _poolAddress) public override view returns (uint) {
        address token0Address = IIUniswapV3Pool(_poolAddress).token0();
        address token1Address = IIUniswapV3Pool(_poolAddress).token1();
        if(token0Address == address(tos)) {
           return 0;
        } else if(token1Address == address(tos)) {
            return 1;
        } else {
            return 3;
        }
    }

    function getAmounts(address npm, address poolAddress, uint256 tokenId)
        public view returns (uint256 amount0, uint256 amount1) {

        (
            uint160 sqrtPriceX96, , , , , ,
        ) = IIUniswapV3Pool(poolAddress).slot0();

        ( , , , , ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity, , , ,
        ) = IINonfungiblePositionManager(npm).positions(tokenId);

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);

    }

    function getDecimals(address token0, address token1) public view returns(uint256 token0Decimals, uint256 token1Decimals) {
        return (IERC20(token0).decimals(), IERC20(token1).decimals());
    }

    function getPriceToken0(address poolAddress) public override view returns (uint256 priceX96) {

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

    /// @inheritdoc ITOSValueCalculator
    function getPriceToken1(address poolAddress) public override  view returns(uint256 priceX96) {

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


    function getSqrtTwapX96(address poolAddress, uint32 twapInterval) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IIUniswapV3Pool(poolAddress).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IIUniswapV3Pool(poolAddress).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56( int32(twapInterval)))
            );
        }
    }

    /// @inheritdoc ITOSValueCalculator
    function getTOSPricePerETH() public override view  returns (uint256 price) {
        (bool isWeth1, bool isTos1, address poolA, address token0A, address token1A) = existPool(tos, weth, 3000);

        if (isWeth1 && isTos1 && token0A == tos) price = getPriceToken1(poolA);
        if (isWeth1 && isTos1 && token1A == tos) price = getPriceToken0(poolA);
    }

    /// @inheritdoc ITOSValueCalculator
    function getETHPricePerTOS() public override view returns (uint256 price) {
        (bool isWeth1, bool isTos1, address poolA, address token0A, address token1A) = existPool(tos, weth, 3000);

        if (isWeth1 && isTos1 && token0A == weth) price = getPriceToken1(poolA);
        if (isWeth1 && isTos1 && token1A == weth) price = getPriceToken0(poolA);
    }

    /// @inheritdoc ITOSValueCalculator
    function getTOSPricePerAsset(address _asset) public override view returns (uint256 price) {
        (, bool isTos1, address poolA, address token0A, address token1A) = existPool(tos, _asset, 3000);

        if (isTos1 && token0A == tos) price = getPriceToken1(poolA);
        if (isTos1 && token1A == tos) price = getPriceToken0(poolA);
    }

    /// @inheritdoc ITOSValueCalculator
    function getAssetPricePerTOS(address _asset) public override view returns (uint256 price) {
        (, bool isTos1, address poolA, address token0A, address token1A) = existPool(tos, _asset, 3000);

        if (isTos1 && token0A == _asset) price = getPriceToken1(poolA);
        if (isTos1 && token1A == _asset) price = getPriceToken0(poolA);
    }

    /// @inheritdoc ITOSValueCalculator
    function existPool(address tokenA, address tokenB, uint24 _fee)
        public override view returns (bool isWeth, bool isTos, address pool, address token0, address token1) {

        if(tokenA == address(0) || tokenB == address(0)) return (false, false, address(0), address(0), address(0));

        (pool, , ) =  computePoolAddress(tokenA, tokenB, _fee);

        token0 = IIUniswapV3Pool(pool).token0();
        token1 = IIUniswapV3Pool(pool).token1();

        if(token0 == address(0) || token1 == address(0)) return (false, false, address(0), address(0), address(0));
        if(token0 == weth || token1 == weth) isWeth = true;
        if(token0 == tos || token1 == tos) isTos = true;
    }

    /// @inheritdoc ITOSValueCalculator
    function computePoolAddress(address tokenA, address tokenB, uint24 _fee)
        public override view returns (address pool, address token0, address token1)
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

    /// @inheritdoc ITOSValueCalculator
    function convertAssetBalanceToWethOrTos(address _asset, uint256 _amount)
        public override view
        returns (bool existedWethPool, bool existedTosPool,  uint256 priceWethOrTosPerAsset, uint256 convertedAmount)
    {
        (bool isWeth, , address pool, address token0, address token1) = existPool(_asset, weth, 3000);

        if (isWeth) {
            existedWethPool = true;
            if (token0 == _asset) priceWethOrTosPerAsset = getPriceToken0(pool);
            else if(token1 == _asset) priceWethOrTosPerAsset = getPriceToken1(pool);

            if(priceWethOrTosPerAsset > 0)  convertedAmount = _amount * priceWethOrTosPerAsset / 1e18;

        } else {
            (, bool isTos, address poolt, address token0t, address token1t) = existPool(_asset, tos, 3000);
            if (isTos){
                existedTosPool = true;
                if (token0t == _asset) priceWethOrTosPerAsset = getPriceToken0(poolt);
                else if(token1t == _asset) priceWethOrTosPerAsset = getPriceToken1(poolt);

                if(priceWethOrTosPerAsset > 0) convertedAmount = _amount * priceWethOrTosPerAsset / 1e18;
            }
        }
    }


}