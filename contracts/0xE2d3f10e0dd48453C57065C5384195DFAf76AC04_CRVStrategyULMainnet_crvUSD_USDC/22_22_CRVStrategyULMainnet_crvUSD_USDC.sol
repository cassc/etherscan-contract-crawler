pragma solidity 0.5.16;

import "./base/CRVStrategyUL.sol";

contract CRVStrategyULMainnet_crvUSD_USDC is CRVStrategyUL {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E);
    address gauge = address(0x95f00391cB5EebCd190EB58728B4CE23DbFa6ac1);
    address crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes32 sushiDex = bytes32(0xcb2d20206d906069351c89a2cb7cdbd96c71998717cd5a82e724d955b654f67a);
    bytes32 uniV3Dex = bytes32(0x8f78a54cb77f4634a5bf3dd452ed6a2e33432c73821be59208661199511cd94f);
    CRVStrategyUL.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,      // rewardPool
      usdc,       // depositToken
      0,          // depositArrayPosition. Find deposit transaction -> input params
      underlying, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      2,          // nTokens
      500         // hodlRatio 5%
    );
    rewardTokens = [crv];
    storedLiquidationPaths[crv][usdc] = [crv, weth, usdc];
    storedLiquidationDexes[crv][usdc] = [sushiDex, uniV3Dex];
  }
}