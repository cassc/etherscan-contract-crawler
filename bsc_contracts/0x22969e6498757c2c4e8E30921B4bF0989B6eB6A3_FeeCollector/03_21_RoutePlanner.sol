// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "pancake-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";

library RoutePlanner {
  function getBases() internal pure returns (address[7] memory) {
    return [
      0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, // WBNB
      0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, // BUSD
      0x55d398326f99059fF775485246999027B3197955, // USDT
      0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c, // BTCB
      0x2170Ed0880ac9A755fd29B2688956BD959F933F8, // ETH
      0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, // USDC
      0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82  // CAKE
    ];
  }

  function findBestRouteExactIn(IPancakeRouter02 router, address tokenIn, address tokenOut, uint256 amountIn) internal view returns (uint256, address[] memory) {
    address[7] memory bases = getBases();
    address[] memory bestPath;
    uint256 bestOut = 0;

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    bestPath = path;

    try router.getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
      if (amounts[amounts.length - 1] > bestOut) {
        bestPath = path;
        bestOut = amounts[amounts.length - 1];
      }
    } catch {}

    for (uint i = 0; i < bases.length; i++) {
      if (bases[i] == tokenIn || bases[i] == tokenOut) { 
        continue;
      }

      path = new address[](3);
      path[0] = tokenIn;
      path[1] = bases[i];
      path[2] = tokenOut;

      try router.getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
        if (amounts[amounts.length - 1] > bestOut) {
          bestPath = path;
          bestOut = amounts[amounts.length - 1];
        }
      } catch {}
    }
    
    return (bestOut, bestPath);
  }

  function findBestRouteExactOut(IPancakeRouter02 router, address tokenIn, address tokenOut, uint256 amountOut) internal view returns (uint256, address[] memory) {
    address[7] memory bases = getBases();
    address[] memory bestPath;
    uint256 bestIn = type(uint256).max;

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    bestPath = path;

    try router.getAmountsIn(amountOut, path) returns (uint[] memory amounts) {
      if (amounts[0] < bestIn) {
        bestPath = path;
        bestIn = amounts[0];
      }
    } catch {}

    for (uint i = 0; i < bases.length; i++) {
      if (bases[i] == tokenIn || bases[i] == tokenOut) { 
        continue;
      }

      path = new address[](3);
      path[0] = tokenIn;
      path[1] = bases[i];
      path[2] = tokenOut;

      try router.getAmountsIn(amountOut, path) returns (uint[] memory amounts) {
        if (amounts[0] < bestIn) {
          bestPath = path;
          bestIn = amounts[0];
        }
      } catch {}
    }

    return (bestIn, bestPath);
  }
}