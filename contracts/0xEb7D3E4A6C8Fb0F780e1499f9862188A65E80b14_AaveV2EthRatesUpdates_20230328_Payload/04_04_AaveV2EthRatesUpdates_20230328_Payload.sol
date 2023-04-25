// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title BAL Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend BAL interest rate parameters on the Aave Ethereum v2liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-bal-interest-rate-upgrade/12423
 */
contract AaveV2EthRatesUpdates_20230328_Payload {
  address public constant INTEREST_RATE_STRATEGY = 0x46158614537A48D51a30073A86b4B73B16D33b53;

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
      AaveV2EthereumAssets.BAL_UNDERLYING,
      INTEREST_RATE_STRATEGY
    );
  }
}