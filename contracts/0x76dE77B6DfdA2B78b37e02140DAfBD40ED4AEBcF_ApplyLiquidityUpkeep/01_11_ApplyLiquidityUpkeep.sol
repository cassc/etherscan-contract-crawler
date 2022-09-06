// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/ILiquidityOps.sol";
import "../../../interfaces/external/chainlink/IKeeperCompatibleInterface.sol";
import "../../../interfaces/external/chainlink/IAggregatorV3Interface.sol";

contract ApplyLiquidityUpkeep is IKeeperCompatibleInterface, Ownable {
    using SafeERC20 for IERC20;

    // Liquidity ops contract address
    address public liquidityOps;

    // Time interval between applyLiquidity() calls
    uint128 public interval;

    // Timestamp of last applyLiquidity() call
    uint256 public lastTimeStamp;

    // Max gas price to check gas feed value
    int256 public maxGasPrice;

    // The liquidity ops LP token balance to check for bypassing the interval
    uint256 public largeBalanceLimit = 10000 * 10**18;

    // TEMPLE-FRAX LP pair token
    IUniswapV2Pair public immutable lpToken;

    // Extra slippage to account for in the minCurveLiquidityAmountOut() function,
    // given curveStableSwap.calc_token_amount() is an approximation.
    // 1e10 precision, so 1% = 1e8
    uint256 public modelSlippage = 5e7;

    // Chainlink Fast Gas Data Feed
    IAggregatorV3Interface public fastGasFeed;

    event IntervalSet(uint256 _interval);
    event FastGasFeedSet(address _fastGasFeed);
    event LiquidityOpsSet(address _liquidityOps);
    event MaxGasPriceSet(int256 _maxGasPrice);
    event ModelSlippageSet(uint256 _modelSlippage);
    event LargeBalanceLimitSet(uint256 _largeBalanceLimit);

    error NotLongEnough(uint256 minExpected);
    error MaxGasZero(int256 gasPrice);
    error GasTooHigh(int256 gasPrice);
    error BalanceLimitZero(uint256 tokenBalance);

    constructor(
        address _liquidityOps,
        uint128 _interval,
        address _lpToken,
        address _fastGasFeed
    ) {
        liquidityOps = _liquidityOps;
        interval = _interval;
        lpToken = IUniswapV2Pair(_lpToken);
        fastGasFeed = IAggregatorV3Interface(_fastGasFeed);
    }

    function setInterval(uint128 _interval) external onlyOwner {
        if (_interval < 3600) revert NotLongEnough(3600);
        interval = _interval;

        emit IntervalSet(_interval);
    }

    function setFastGasFeed(address _fastGasFeed) external onlyOwner {
        fastGasFeed = IAggregatorV3Interface(_fastGasFeed);

        emit FastGasFeedSet(_fastGasFeed);
    }

    function setLiquidityOps(address _liquidityOps) external onlyOwner {
        liquidityOps = _liquidityOps;

        emit LiquidityOpsSet(_liquidityOps);
    }

    function setMaxGasPrice(int256 _maxGasPrice) external onlyOwner {
        if (_maxGasPrice == 0) revert MaxGasZero(_maxGasPrice);
        maxGasPrice = _maxGasPrice;

        emit MaxGasPriceSet(_maxGasPrice);
    }

    function setModelSlippage(uint256 _modelSlippage) external onlyOwner {
        modelSlippage = _modelSlippage;

        emit ModelSlippageSet(_modelSlippage);
    }

    function setLargeBalanceLimit(uint256 _largeBalanceLimit) external onlyOwner {
        if (_largeBalanceLimit == 0) revert BalanceLimitZero(_largeBalanceLimit);
        largeBalanceLimit = _largeBalanceLimit;

        emit LargeBalanceLimitSet(_largeBalanceLimit);
    }

    // Called by Chainlink Keepers to check if upkeep should be executed
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 lpBalance = lpToken.balanceOf(liquidityOps);
        (, int256 feedValue, , , ) = fastGasFeed.latestRoundData();
        if (lpBalance == 0 || feedValue > maxGasPrice) return (false, checkData);

        // Run if there's a sizable amount of LP, otherwise after a period of time since the last run
        upkeepNeeded = (lpBalance >= largeBalanceLimit ||
            (block.timestamp - lastTimeStamp) > interval);

        uint256 minCurveTokenAmount = ILiquidityOps(liquidityOps)
            .minCurveLiquidityAmountOut(lpBalance, modelSlippage);

        performData = abi.encode(minCurveTokenAmount);
    }

    // Called by Chainlink Keepers to apply liquidity
    function performUpkeep(bytes calldata performData) external override {
        // Check upkeep conditions again
        uint256 lpBalance = lpToken.balanceOf(liquidityOps);
        (, int256 feedValue, , , ) = fastGasFeed.latestRoundData();

        if (lpBalance == 0) revert BalanceLimitZero(lpBalance);

        if (lpBalance < largeBalanceLimit) {
            if ((block.timestamp - lastTimeStamp) <= interval) revert NotLongEnough(interval);
        }

        // Add a 1.25x check of the maxGasPrice to account for a potential spike in gas price
        if (feedValue > (maxGasPrice * 125) / 100) revert GasTooHigh(feedValue);

        uint256 minCurveTokenAmount = abi.decode(performData, (uint256));

        ILiquidityOps(liquidityOps).applyLiquidity(
            lpBalance,
            minCurveTokenAmount
        );
        lastTimeStamp = block.timestamp;
    }
}