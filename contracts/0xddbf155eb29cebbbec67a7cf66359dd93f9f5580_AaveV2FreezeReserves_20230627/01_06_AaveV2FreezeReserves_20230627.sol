// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title Freeze TUSD Reserve Aave V2 ETH Pool
 * @author @Gauntlet - Powered By Skyward
 * - Snapshot: Direct-to-AIP framework
 * - Discussion: https://governance.aave.com/t/arfc-chaos-labs-v2-to-v3-migration-next-steps/13701
 */
contract AaveV2FreezeReserves_20230627 is IProposalGenericExecutor {
  address public constant TUSD = AaveV2EthereumAssets.TUSD_UNDERLYING;

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(TUSD);
  }
}