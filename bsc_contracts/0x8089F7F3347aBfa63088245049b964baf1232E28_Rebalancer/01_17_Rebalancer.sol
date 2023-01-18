// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "../interfaces/IIndexToken.sol";
import "pancake-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "../interfaces/IOracleRegistry.sol";
import "../lib/RoutePlanner.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract Rebalancer is AutomationCompatible {
  event Swap(address indexed index, address assetIn, uint256 amountIn, address assetOut, uint256 amountOut);

  struct RebalanceDesc {
    IIndexToken token;
    IIndexToken.Asset[] newAssets;
    TradeDesc[] trades;
  }

  mapping (IIndexToken => mapping (address => uint256)) weights;
  mapping (IIndexToken => uint256) timestamps;
  mapping (IIndexToken => uint256) intervals;

  struct TradeDesc {
    address[] path;
    uint256 amountIn;
    uint256 amountOut;
    bool fixedIn;
  }

  IPancakeRouter02 immutable router;
  IOracleRegistry immutable oracles;

  constructor(IPancakeRouter02 router_, IOracleRegistry oracles_) {
    router = router_;
    oracles = oracles_;
  }

  function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
    (address token, address usdt) = abi.decode(checkData, (address, address));
    uint256 interval = intervals[IIndexToken(token)];
    if (interval > 0 && block.timestamp - timestamps[IIndexToken(token)] > interval) {
      computeRebalance(IIndexToken(token), usdt);
      return (true, checkData);
    } else {
      return (false, "");
    }
  }

  function performUpkeep(bytes calldata performData) external {
    (address token, address usdt) = abi.decode(performData, (address, address));
    uint256 interval = intervals[IIndexToken(token)];
    require(interval > 0 && block.timestamp - timestamps[IIndexToken(token)] > interval);
    timestamps[IIndexToken(token)] = block.timestamp;
    doRebalance(IIndexToken(token), usdt);
  }

  function register(IIndexToken token, uint256[] calldata weights_, uint256 interval) external {
    require(msg.sender == token.getOwner(), "not owner");
    IIndexToken.Asset[] memory assets = token.getAssets();
    for (uint256 i = 0; i < assets.length; i++) {
      weights[token][assets[i].assetToken] = weights_[i];
    }
    intervals[token] = interval;
  }

  function doRebalance(IIndexToken token, address usdt) internal {
    executeRebalance(computeRebalance(token, usdt));
    checkCollaterals(token);
  }

  function computeWeightSum(IIndexToken token) internal view returns (uint256) {
    uint256 result = 0;
    IIndexToken.Asset[] memory assets = token.getAssets();
    for (uint256 i = 0; i < assets.length; i++) {
      result += weights[token][assets[i].assetToken];
    }
    return result;
  }

  function computeRebalance(IIndexToken token, address usdt) internal view returns (RebalanceDesc memory rebalance) {
    rebalance.token = token;
    rebalance.newAssets = token.getAssets();

    uint256 totalSupply = token.totalSupply();
    uint256 fullValue = 0;
    for (uint256 i = 0; i < rebalance.newAssets.length; i++) {
      IIndexToken.Asset memory asset = rebalance.newAssets[i];
      fullValue += oracles.convert(asset.assetToken, usdt, asset.amount);
    }

    rebalance.trades = new TradeDesc[](rebalance.newAssets.length);

    int256 usdtAmount = 0;
    uint256 usdtIndex = type(uint256).max;

    uint256 weightSum = computeWeightSum(token);
    
    for (uint256 i = 0; i < rebalance.newAssets.length; i++) {
      IIndexToken.Asset memory asset = rebalance.newAssets[i];
      if (asset.assetToken == usdt) {
        usdtIndex = i;
        usdtAmount += int256(asset.amount);
        continue;
      }

      uint256 targetValue = 0;
      {
        uint256 targetWeight = weights[token][asset.assetToken];
        targetValue = Math.mulDiv(fullValue, targetWeight, weightSum);
      }
      uint256 targetAmount = oracles.convert(usdt, asset.assetToken, targetValue);
      uint256 assetAmount = asset.amount;
      rebalance.newAssets[i].amount = targetAmount;
      
      if (targetAmount > assetAmount) {
        rebalance.trades[i].path = new address[](2);
        rebalance.trades[i].path[0] = usdt;
        rebalance.trades[i].path[1] = asset.assetToken;
        rebalance.trades[i].amountOut = Math.mulDiv(totalSupply, targetAmount - assetAmount, 10**18, Math.Rounding.Up);
        rebalance.trades[i].amountIn = oracles.convert(asset.assetToken, usdt, rebalance.trades[i].amountOut);
        rebalance.trades[i].fixedIn = false;
        rebalance.trades[i] = optimizeRoute(rebalance.trades[i], 10);
        usdtAmount -= int256(rebalance.trades[i].amountIn);
      } else if (targetAmount < assetAmount) {
        rebalance.trades[i].path = new address[](2);
        rebalance.trades[i].path[0] = asset.assetToken;
        rebalance.trades[i].path[1] = usdt;
        rebalance.trades[i].amountIn = Math.mulDiv(totalSupply, assetAmount - targetAmount, 10**18, Math.Rounding.Down);
        rebalance.trades[i].amountOut = oracles.convert(asset.assetToken, usdt, rebalance.trades[i].amountIn);
        rebalance.trades[i].fixedIn = true;
        rebalance.trades[i] = optimizeRoute(rebalance.trades[i], 10);
        usdtAmount += int256(rebalance.trades[i].amountOut);
      }
    }
    rebalance.trades = sortTrades(rebalance.trades);
    if (usdtIndex != type(uint256).max) {
      // usdt is in, make it floating
      require(usdtAmount >= 0, "usdt went negative");
      rebalance.newAssets[usdtIndex].amount = Math.mulDiv(uint256(usdtAmount), 10**18, totalSupply);
    }

    return rebalance;
  }

  function optimizeRoute(TradeDesc memory trade, uint16 slippage) internal view returns (TradeDesc memory) {
    if (trade.path.length == 0) {
      return trade;
    }
    if (trade.fixedIn) {
      (uint256 amountOut, address[] memory path) = RoutePlanner.findBestRouteExactIn(router, trade.path[0], trade.path[1], trade.amountIn);
      require(amountOut >= trade.amountOut * (1000 - slippage) / 1000, "exactIn: not enough");
      trade.path = path;
      trade.amountOut = amountOut * (1000 - slippage) / 1000;
    } else {
      (uint256 amountIn, address[] memory path) = RoutePlanner.findBestRouteExactOut(router, trade.path[0], trade.path[1], trade.amountOut);
      require(amountIn <= trade.amountIn * 1000 / (1000 - slippage), "exactOut: not enough");
      trade.path = path;
      trade.amountIn = amountIn * (1000 + slippage) / 1000;
    }
    return trade;
  }

  function compareTrades(TradeDesc memory trade0, TradeDesc memory trade1) internal pure returns (int8) {
    // we want to sell first, buy second
    // sells have fixedIn == true

    if (trade0.fixedIn && !trade1.fixedIn) {
      return -1;
    }
    if (!trade0.fixedIn && trade1.fixedIn) {
      return 1;
    }
    return 0;
  }

  // TODO optimize
  function sortTrades(TradeDesc[] memory trades) internal pure returns (TradeDesc[] memory) {
    uint256 pos = 0;
    while (pos < trades.length) {
      if (pos == 0 || compareTrades(trades[pos], trades[pos - 1]) >= 0) {
        pos += 1;
      } else {
        TradeDesc memory t = trades[pos - 1];
        trades[pos - 1] = trades[pos];
        trades[pos] = t;
        pos -= 1;
      }
    }

    return trades;
  }

  function executeRebalance(RebalanceDesc memory rebalanceDesc) internal {
    IIndexToken token = rebalanceDesc.token;

    for (uint256 i = 0; i < rebalanceDesc.trades.length; i++) {
      executeTrade(token, rebalanceDesc.trades[i]);
    }

    token.setAssets(rebalanceDesc.newAssets);
  }

  function executeTrade(IIndexToken token, TradeDesc memory trade) internal {
    address[] memory path = trade.path;
    if (path.length == 0) {
      return;
    }
    IERC20 tokenIn = IERC20(path[0]);
    IERC20 tokenOut = IERC20(path[path.length - 1]);
    SafeERC20.safeApprove(tokenIn, address(router), trade.amountIn);
    token.transferAsset(address(tokenIn), address(this), trade.amountIn);
    uint256[] memory amounts;
    if (trade.fixedIn) {
      amounts = router.swapExactTokensForTokens(
        trade.amountIn,
        trade.amountOut,
        path,
        address(this),
        block.timestamp
      );
    } else {
      amounts = router.swapTokensForExactTokens(
        trade.amountOut,
        trade.amountIn,
        path,
        address(this),
        block.timestamp
      );
    }
    emit Swap(
      address(token),
      address(tokenIn),
      amounts[0],
      address(tokenOut),
      amounts[amounts.length - 1]
    );

    SafeERC20.safeApprove(tokenIn, address(router), 0);
    SafeERC20.safeTransfer(tokenIn, address(token), trade.amountIn - amounts[0]);
    SafeERC20.safeTransfer(tokenOut, address(token), amounts[amounts.length - 1]);
  }

  error Undercollateralized(address asset, uint256 assetBalance, uint256 requiredBalance);
  function checkCollaterals(IIndexToken token) internal view {
    IIndexToken.Asset[] memory assets = token.getAssets();
    uint256 totalSupply = token.totalSupply();
    for (uint256 i = 0; i < assets.length; i++) {
      IERC20Metadata assetToken = IERC20Metadata(assets[i].assetToken);
      uint256 assetBalance = assetToken.balanceOf(address(token));
      uint256 requiredBalance = assets[i].amount * totalSupply / 10**18;
      if (assetBalance < requiredBalance) {
        revert Undercollateralized(address(assetToken), assetBalance, requiredBalance);
      }
    }
  }
}