// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IPoolConfigurator, ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title This proposal change cbETH supply caps on Aave V3 Polygon
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xe6bea8781d645318c6e83f98229ae346f45ff3219bdbd72da5dfd40105a9042c
 * - Discussion: https://governance.aave.com/t/arfc-activate-emode-for-cbeth-aave-ethereum-v3/12074
 */

contract AaveV3EthCBETHEmodeActivation is IProposalGenericExecutor {
  address public constant CBETH = AaveV3EthereumAssets.cbETH_UNDERLYING;

  uint8 public constant EMODE_CATEGORY = 1;

  function execute() external {
    AaveV3Ethereum.POOL_CONFIGURATOR.setAssetEModeCategory(CBETH, EMODE_CATEGORY);
  }
}