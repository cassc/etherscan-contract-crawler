// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {ILendingPoolConfigurator, ConfiguratorInputTypes} from 'aave-address-book/AaveV2.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title Aave governance payload to freeze the BUSD asset on Aave v2 Ethereum
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x7fe7d372601aa2864cbe21071bd2fda10bf22aa8f66076db276818a2d6808bef
 * - Discussion: https://governance.aave.com/t/arfc-freeze-busd-on-aave-v2/11842
 */
contract AaveV2EthFreezeBUSD is IProposalGenericExecutor {
  address public constant BUSD = AaveV2EthereumAssets.BUSD_UNDERLYING;

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(BUSD);
  }
}