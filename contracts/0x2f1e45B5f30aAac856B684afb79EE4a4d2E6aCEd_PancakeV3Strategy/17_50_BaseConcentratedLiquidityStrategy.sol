// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "../../HarvestableApyFlowVault.sol";
import "../../libraries/Utils.sol";
import "../../libraries/SafeAssetConverter.sol";
import "../../libraries/PricesLibrary.sol";
import "../../ChainlinkPriceFeedAggregator.sol";
import "../../libraries/ConcentratedLiquidityLibrary.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract BaseConcentratedLiquidityStrategy is HarvestableApyFlowVault {
    using SafeERC20 for IERC20;
    using SafeAssetConverter for IAssetConverter;
    using PricesLibrary for ChainlinkPriceFeedAggregator;

    error PoolPriceDeviationTooHigh(uint160 oracleSqrtPrice, uint160 poolSqrtPrice);

    struct PositionData {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    uint256 public lastPricePerToken;

    event LiquidityReadded(uint256 lastPricePerToken, uint256 pricePerTokensBefore, uint256 pricePerTokenAfter);

    ChainlinkPriceFeedAggregator public immutable pricesOracle;
    IAssetConverter public immutable assetConverter;
    int24 public immutable ticksDown;
    int24 public immutable ticksUp;
    uint256 public immutable allowedPoolOracleDeviation = 10;

    constructor(
        int24 _ticksDown,
        int24 _ticksUp,
        ChainlinkPriceFeedAggregator _pricesOracle,
        IAssetConverter _assetConverter
    ) {
        pricesOracle = _pricesOracle;
        assetConverter = _assetConverter;
        ticksDown = _ticksDown;
        ticksUp = _ticksUp;
        lastPricePerToken = 10 ** decimals();
    }

    function token0() public view virtual returns (address);

    function token1() public view virtual returns (address);

    function _isPositionExists() internal view virtual returns (bool);

    function _increaseLiquidity(uint256 amount0, uint256 amount1) internal virtual;

    function _decreaseLiquidity(uint128 liquidity) internal virtual returns (uint256 amount0, uint256 amount1);

    function _mint(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) internal virtual;

    function getPoolData() public view virtual returns (int24 currentTick, uint160 sqrtPriceX96);

    function getPositionData() public view virtual returns (PositionData memory data);

    function _collectAllAndBurn() internal virtual;

    function _collect() internal virtual;

    function _tickSpacing() internal view virtual returns (int24);

    modifier checkDeviation() {
        uint160 oracleSqrtPrice = _getSqrtPriceX96FromOracle();
        (, uint160 poolSqrtPrice) = getPoolData();
        uint160 pricesDiff =
            oracleSqrtPrice > poolSqrtPrice ? oracleSqrtPrice - poolSqrtPrice : poolSqrtPrice - oracleSqrtPrice;
        uint256 deviation = pricesDiff * 1000 / poolSqrtPrice;

        if (deviation > allowedPoolOracleDeviation) {
            revert PoolPriceDeviationTooHigh(oracleSqrtPrice, poolSqrtPrice);
        }
        _;
    }

    function _performApprovals() internal virtual {
        Utils.approveIfZeroAllowance(asset(), address(assetConverter));
        Utils.approveIfZeroAllowance(token0(), address(assetConverter));
        Utils.approveIfZeroAllowance(token1(), address(assetConverter));
    }

    function _isInRange() internal view returns (bool) {
        (int24 tickLower, int24 currentTick, int24 tickUpper) = _getTicks();
        return (tickLower <= currentTick) && (currentTick <= tickUpper);
    }

    function _getTicks() internal view returns (int24 tickLower, int24 currentTick, int24 tickUpper) {
        (currentTick,) = getPoolData();
        if (_isPositionExists()) {
            PositionData memory data = getPositionData();
            tickLower = data.tickLower;
            tickUpper = data.tickUpper;
        } else {
            tickLower = currentTick - ticksDown;
            tickUpper = currentTick + ticksUp;
            int24 spacing = _tickSpacing();
            tickLower = (tickLower / spacing) * spacing;
            tickUpper = (tickUpper / spacing) * spacing;
        }
    }

    function _getSqrtPrices()
        internal
        view
        returns (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96)
    {
        (int24 tickLower,, int24 tickUpper) = _getTicks();
        sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        (, sqrtPriceX96) = getPoolData();
        sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    function _mintNewPosition(uint256 amount0, uint256 amount1) internal virtual {
        (int24 tickLower, int24 currentTick, int24 tickUpper) = _getTicks();
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(currentTick),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0,
            amount1
        );
        if (liquidity == 0) {
            return;
        }
        _mint(tickLower, tickUpper, amount0, amount1);
    }

    function _increaseLiquidityOrMintPosition(uint256 amount0, uint256 amount1) internal {
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        uint128 liquidity =
            LiquidityAmounts.getLiquidityForAmounts(sqrtPriceAX96, sqrtPriceX96, sqrtPriceBX96, amount0, amount1);
        if (liquidity == 0) {
            return;
        }
        if (!_isPositionExists()) {
            _mintNewPosition(amount0, amount1);
        } else {
            _increaseLiquidity(amount0, amount1);
        }
    }

    function _totalAssets() internal view virtual override returns (uint256 assets) {
        if (!_isPositionExists()) {
            return 0;
        }
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, sqrtPriceAX96, sqrtPriceBX96, getPositionData().liquidity
        );
        uint256 valueInUSD;
        valueInUSD += pricesOracle.convertToUSD(token0(), amount0);
        valueInUSD += pricesOracle.convertToUSD(token1(), amount1);
        assets = pricesOracle.convertFromUSD(valueInUSD, asset());
    }

    function _deposit(uint256 assets) internal virtual override checkDeviation {
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        (uint256 amountFor0, uint256 amountFor1) = ConcentratedLiquidityLibrary.getAmountsForLiquidityProviding(
            sqrtPriceAX96, sqrtPriceX96, sqrtPriceBX96, assets
        );
        uint256 amount0 = assetConverter.safeSwap(asset(), token0(), amountFor0);
        uint256 amount1 = assetConverter.safeSwap(asset(), token1(), amountFor1);
        _increaseLiquidityOrMintPosition(amount0, amount1);
        assetConverter.safeSwap(token0(), asset(), IERC20(token0()).balanceOf(address(this)));
        assetConverter.safeSwap(token1(), asset(), IERC20(token1()).balanceOf(address(this)));
    }

    function _redeem(uint256 shares) internal virtual override checkDeviation returns (uint256 assets) {
        uint128 liquidity = uint128((getPositionData().liquidity * shares) / totalSupply());

        (uint256 amount0, uint256 amount1) = _decreaseLiquidity(liquidity);

        _collect();

        if (getPositionData().liquidity == 0) {
            _collectAllAndBurn();
        }

        assets += assetConverter.safeSwap(token0(), asset(), amount0);
        assets += assetConverter.safeSwap(token1(), asset(), amount1);
    }

    function _readdLiquidity() internal virtual {
        _redeem(totalSupply());
        _deposit(IERC20(asset()).balanceOf(address(this)));
    }

    function _harvest() internal virtual override {
        if (!_isPositionExists()) return;
        _collect();
        assetConverter.safeSwap(token0(), asset(), IERC20(token0()).balanceOf(address(this)));
        assetConverter.safeSwap(token1(), asset(), IERC20(token1()).balanceOf(address(this)));
    }

    function _getSqrtPriceX96FromOracle() internal view returns (uint160 sqrtPriceX96) {
        uint256 token0Rate = pricesOracle.getRate(token0());
        uint256 token1Rate = pricesOracle.getRate(token1());

        // price = (10 ** token1Decimals) * token0Rate / ((10 ** token0Decimals) * token1Rate)
        // sqrtPriceX96 = sqrt(price * 2^192)

        // overflows only if token0 is 2**64 times more expensive than token1 (considered non-likely)
        uint256 factor1 = Math.mulDiv(token0Rate, 2 ** 96, token1Rate);

        // Cannot overflow if token1Decimals <= 18 and token0Decimals <= 18
        uint256 factor2 =
            Math.mulDiv(10 ** IERC20Metadata(token1()).decimals(), 2 ** 96, 10 ** IERC20Metadata(token0()).decimals());

        uint128 factor1Sqrt = uint128(Math.sqrt(factor1));
        uint128 factor2Sqrt = uint128(Math.sqrt(factor2));

        sqrtPriceX96 = factor1Sqrt * factor2Sqrt;
    }

    function readdLiquidity() public virtual checkDeviation {
        _harvest(false);

        uint160 sqrtPriceX96 = _getSqrtPriceX96FromOracle();
        PositionData memory data = getPositionData();

        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(data.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(data.tickUpper);
        bool isInRebalanceRange = (sqrtPriceX96 < sqrtPriceLowerX96) || (sqrtPriceX96 >= sqrtPriceUpperX96);

        uint256 pricePerTokenBefore = pricePerToken();
        _readdLiquidity();
        uint256 pricePerTokenAfter = pricePerToken();

        require(isInRebalanceRange || (pricePerTokenAfter >= (lastPricePerToken * 1001) / 1000));

        emit LiquidityReadded(lastPricePerToken, pricePerTokenBefore, pricePerTokenAfter);

        lastPricePerToken = pricePerTokenAfter;
    }
}