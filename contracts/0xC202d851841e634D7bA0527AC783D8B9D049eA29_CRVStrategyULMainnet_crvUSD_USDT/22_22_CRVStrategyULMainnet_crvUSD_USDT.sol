pragma solidity 0.5.16;

import "./base/CRVStrategyUL.sol";

contract CRVStrategyULMainnet_crvUSD_USDT is CRVStrategyUL {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x390f3595bCa2Df7d23783dFd126427CCeb997BF4);
    address gauge = address(0x4e6bB6B7447B7B2Aa268C16AB87F4Bb48BF57939);
    address crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes32 sushiDex = bytes32(0xcb2d20206d906069351c89a2cb7cdbd96c71998717cd5a82e724d955b654f67a);
    bytes32 uniV3Dex = bytes32(0x8f78a54cb77f4634a5bf3dd452ed6a2e33432c73821be59208661199511cd94f);
    CRVStrategyUL.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,      // rewardPool
      usdt,       // depositToken
      0,          // depositArrayPosition. Find deposit transaction -> input params
      underlying, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      2,          // nTokens
      500         // hodlRatio 5%
    );
    rewardTokens = [crv];
    storedLiquidationPaths[crv][usdt] = [crv, weth, usdt];
    storedLiquidationDexes[crv][usdt] = [sushiDex, uniV3Dex];
  }
}