// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IPoolConfigurator, ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title This proposal change cbETH supply caps on Aave V3 Polygon
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: Direct-to-AIP process
 * - Discussion: https://governance.aave.com/t/arfc-increase-supply-cap-for-cbeth-aave-ethereum-v3/11869
 */

contract AaveV3EthCbETHCapsPayload is IProposalGenericExecutor {
  address public constant CBETH = AaveV3EthereumAssets.cbETH_UNDERLYING;

  uint256 public constant CBETH_SUPPLY_CAP = 20_000;

  function execute() external {
    IPoolConfigurator configurator = AaveV3Ethereum.POOL_CONFIGURATOR;

    configurator.setSupplyCap(CBETH, CBETH_SUPPLY_CAP);
  }
}