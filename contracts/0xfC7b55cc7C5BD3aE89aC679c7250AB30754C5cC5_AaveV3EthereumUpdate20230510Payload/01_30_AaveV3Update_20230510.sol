// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEngine,EngineFlags,Rates} from 'aave-helpers/v3-config-engine/AaveV3PayloadBase.sol';
import {
  AaveV3PayloadArbitrum,
  AaveV3ArbitrumAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadArbitrum.sol';
import {
  AaveV3PayloadEthereum,
  AaveV3EthereumAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';
import {
  AaveV3PayloadPolygon,
  AaveV3PolygonAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadPolygon.sol';
import {
  AaveV3PayloadOptimism,
  AaveV3OptimismAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadOptimism.sol';
import {
  AaveV3PayloadAvalanche,
  AaveV3AvalancheAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadAvalanche.sol';

contract AaveV3ArbitrumUpdate20230510Payload is AaveV3PayloadArbitrum {
  function rateStrategiesUpdates() public pure override returns (IEngine.RateStrategyUpdate[] memory) {
    IEngine.RateStrategyUpdate[] memory rateStrategyUpdates = new IEngine.RateStrategyUpdate[](3);

    Rates.RateStrategyParams memory paramsEURS_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(600),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[0] = IEngine.RateStrategyUpdate({
      asset: AaveV3ArbitrumAssets.EURS_UNDERLYING,
      params: paramsEURS_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsUSDC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(350),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[1] = IEngine.RateStrategyUpdate({
      asset: AaveV3ArbitrumAssets.USDC_UNDERLYING,
      params: paramsUSDC_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsWBTC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(400),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[2] = IEngine.RateStrategyUpdate({
      asset: AaveV3ArbitrumAssets.WBTC_UNDERLYING,
      params: paramsWBTC_UNDERLYING
    });

    return rateStrategyUpdates;
  }
}

contract AaveV3EthereumUpdate20230510Payload is AaveV3PayloadEthereum {
  function borrowsUpdates() public pure override returns (IEngine.BorrowUpdate[] memory) {
    IEngine.BorrowUpdate[] memory borrowUpdates = new IEngine.BorrowUpdate[](1);


    borrowUpdates[0] = IEngine.BorrowUpdate({
      asset: AaveV3EthereumAssets.CRV_UNDERLYING,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT,
      reserveFactor: 3500
    });

    return borrowUpdates;
  }  function rateStrategiesUpdates() public pure override returns (IEngine.RateStrategyUpdate[] memory) {
    IEngine.RateStrategyUpdate[] memory rateStrategyUpdates = new IEngine.RateStrategyUpdate[](3);

    Rates.RateStrategyParams memory paramsUSDC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(350),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[0] = IEngine.RateStrategyUpdate({
      asset: AaveV3EthereumAssets.USDC_UNDERLYING,
      params: paramsUSDC_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsUSDT_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: _bpsToRay(8000),
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: EngineFlags.KEEP_CURRENT,
      variableRateSlope2: _bpsToRay(7500),
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[1] = IEngine.RateStrategyUpdate({
      asset: AaveV3EthereumAssets.USDT_UNDERLYING,
      params: paramsUSDT_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsWBTC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(400),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[2] = IEngine.RateStrategyUpdate({
      asset: AaveV3EthereumAssets.WBTC_UNDERLYING,
      params: paramsWBTC_UNDERLYING
    });

    return rateStrategyUpdates;
  }
}

contract AaveV3PolygonUpdate20230510Payload is AaveV3PayloadPolygon {
  function borrowsUpdates() public pure override returns (IEngine.BorrowUpdate[] memory) {
    IEngine.BorrowUpdate[] memory borrowUpdates = new IEngine.BorrowUpdate[](1);


    borrowUpdates[0] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.CRV_UNDERLYING,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT,
      reserveFactor: 3500
    });

    return borrowUpdates;
  }  function rateStrategiesUpdates() public pure override returns (IEngine.RateStrategyUpdate[] memory) {
    IEngine.RateStrategyUpdate[] memory rateStrategyUpdates = new IEngine.RateStrategyUpdate[](4);

    Rates.RateStrategyParams memory paramsDPI_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(1000),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[0] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.DPI_UNDERLYING,
      params: paramsDPI_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsEURS_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(600),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[1] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.EURS_UNDERLYING,
      params: paramsEURS_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsUSDC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(350),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[2] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.USDC_UNDERLYING,
      params: paramsUSDC_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsWBTC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(400),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[3] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.WBTC_UNDERLYING,
      params: paramsWBTC_UNDERLYING
    });

    return rateStrategyUpdates;
  }
}

contract AaveV3OptimismUpdate20230510Payload is AaveV3PayloadOptimism {
  function rateStrategiesUpdates() public pure override returns (IEngine.RateStrategyUpdate[] memory) {
    IEngine.RateStrategyUpdate[] memory rateStrategyUpdates = new IEngine.RateStrategyUpdate[](2);

    Rates.RateStrategyParams memory paramsUSDC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(350),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[0] = IEngine.RateStrategyUpdate({
      asset: AaveV3OptimismAssets.USDC_UNDERLYING,
      params: paramsUSDC_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsWBTC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(400),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[1] = IEngine.RateStrategyUpdate({
      asset: AaveV3OptimismAssets.WBTC_UNDERLYING,
      params: paramsWBTC_UNDERLYING
    });

    return rateStrategyUpdates;
  }
}

contract AaveV3AvalancheUpdate20230510Payload is AaveV3PayloadAvalanche {
  function rateStrategiesUpdates() public pure override returns (IEngine.RateStrategyUpdate[] memory) {
    IEngine.RateStrategyUpdate[] memory rateStrategyUpdates = new IEngine.RateStrategyUpdate[](2);

    Rates.RateStrategyParams memory paramsUSDC_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(350),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[0] = IEngine.RateStrategyUpdate({
      asset: AaveV3AvalancheAssets.USDC_UNDERLYING,
      params: paramsUSDC_UNDERLYING
    });

    Rates.RateStrategyParams memory paramsWBTCe_UNDERLYING = Rates.RateStrategyParams({
      optimalUsageRatio: EngineFlags.KEEP_CURRENT,
      baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
      variableRateSlope1: _bpsToRay(400),
      variableRateSlope2: EngineFlags.KEEP_CURRENT,
      stableRateSlope1: EngineFlags.KEEP_CURRENT,
      stableRateSlope2: EngineFlags.KEEP_CURRENT,
      baseStableRateOffset: EngineFlags.KEEP_CURRENT,
      stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
      optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
    });

    rateStrategyUpdates[1] = IEngine.RateStrategyUpdate({
      asset: AaveV3AvalancheAssets.WBTCe_UNDERLYING,
      params: paramsWBTCe_UNDERLYING
    });

    return rateStrategyUpdates;
  }
}