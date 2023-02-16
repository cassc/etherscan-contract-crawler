// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title wETH Interest Rate Curve - Ethereum v2
 * @author Llama
 * @notice Upgrade wETH interest rate on Ethereum v2 to match Ethereum v3 Liquidity Pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-weth-wsteth-interest-rate-curve-ethereum-network/11372
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x9ae28e9c82c5fc0d24cf1df788094e959d99f906d11b89e455a60ee16b071d6f
 */
contract AaveV2EthwETHIRPayload is IProposalGenericExecutor {
  address public constant INTEREST_RATE_STRATEGY = 0xb8975328Aa52c00B9Ec1e11e518C4900f2e6C62a;

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      INTEREST_RATE_STRATEGY
    );
  }
}