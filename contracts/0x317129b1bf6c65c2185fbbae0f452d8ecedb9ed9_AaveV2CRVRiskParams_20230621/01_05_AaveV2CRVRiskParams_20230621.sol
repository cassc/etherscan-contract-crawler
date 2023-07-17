// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title This proposal updates CRV risk params on Aave V2 Ethereum
 * @author @yonikesel - ChaosLabsInc
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x87a32d14a55f5da504b49565d582a4234f26df4c74ac39c083427d6cbd65999b
 * - Discussion: https://governance.aave.com/t/arfc-chaos-labs-risk-parameter-updates-crv-aave-v2-ethereum-2023-06-15/13709
 */
contract AaveV2CRVRiskParams_20230621 {
  uint256 public constant CRV_LTV = 49_00; /// 52 -> 49
  uint256 public constant CRV_LIQUIDATION_THRESHOLD = 55_00; // 58 -> 55
  uint256 public constant CRV_LIQUIDATION_BONUS = 10800; //unchanged

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
      AaveV2EthereumAssets.CRV_UNDERLYING,
      CRV_LTV,
      CRV_LIQUIDATION_THRESHOLD,
      CRV_LIQUIDATION_BONUS
    );
  }
}