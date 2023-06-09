pragma solidity 0.5.16;

import "./base/ConvexStrategyUL_V2.sol";

contract ConvexStrategyMainnet_crvUSD_USDC is ConvexStrategyUL_V2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E); // Info -> LP Token address
    address rewardPool = address(0x44D8FaB7CD8b7877D5F79974c2F501aF6E65AbBA); // Info -> Rewards contract address
    address crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    bytes32 sushiDex = bytes32(0xcb2d20206d906069351c89a2cb7cdbd96c71998717cd5a82e724d955b654f67a);
    bytes32 uniV3Dex = bytes32(0x8f78a54cb77f4634a5bf3dd452ed6a2e33432c73821be59208661199511cd94f);
    ConvexStrategyUL_V2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, // rewardPool
      182,  // Pool id: Info -> Rewards contract address -> read -> pid
      usdc, // depositToken
      0, //depositArrayPosition. Find deposit transaction -> input params
      underlying, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      2, //nTokens -> total number of deposit tokens
      false, //metaPool -> if LP token address == pool address (at curve)
      500 // hodlRatio 5%
    );
    rewardTokens = [crv, cvx];
    storedLiquidationPaths[crv][weth] = [crv, weth];
    storedLiquidationDexes[crv][weth] = [sushiDex];
    storedLiquidationPaths[cvx][weth] = [cvx, weth];
    storedLiquidationDexes[cvx][weth] = [sushiDex];
    storedLiquidationPaths[weth][usdc] = [weth, usdc];
    storedLiquidationDexes[weth][usdc] = [uniV3Dex];
  }
}