// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3PayloadEthereum, IEngine, EngineFlags, Rates} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @title AaveV3EthRatesUpdates_20230328
 * @author Llama
 * @dev Amend the BAL interest rate parameters on the Aave Ethereum v3 Liquidity Pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-bal-interest-rate-upgrade/12423
 */
contract AaveV3EthRatesUpdates_20230328 is AaveV3PayloadEthereum {
  function rateStrategiesUpdates()
    public
    pure
    override
    returns (IEngine.RateStrategyUpdate[] memory)
  {
    IEngine.RateStrategyUpdate[] memory ratesUpdate = new IEngine.RateStrategyUpdate[](1);

    ratesUpdate[0] = IEngine.RateStrategyUpdate({
      asset: AaveV2EthereumAssets.BAL_UNDERLYING,
      params: Rates.RateStrategyParams({
        optimalUsageRatio: EngineFlags.KEEP_CURRENT,
        baseVariableBorrowRate: _bpsToRay(5_00),
        variableRateSlope1: _bpsToRay(22_00),
        variableRateSlope2: EngineFlags.KEEP_CURRENT,
        stableRateSlope1: _bpsToRay(22_00),
        stableRateSlope2: _bpsToRay(150_00),
        baseStableRateOffset: _bpsToRay(5_00),
        stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
        optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
      })
    });

    return ratesUpdate;
  }
}