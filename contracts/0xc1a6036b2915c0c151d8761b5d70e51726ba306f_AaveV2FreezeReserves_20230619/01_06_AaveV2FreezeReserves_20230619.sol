// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title Chaos Labs V2 to V3 Migration Next Steps
 * @author @Chaos Labs - Powered By Skyward
 * - Snapshot: Direct-to-AIP framework
 * - Discussion: https://governance.aave.com/t/arfc-chaos-labs-v2-to-v3-migration-next-steps/13701
 */
contract AaveV2FreezeReserves_20230619 is IProposalGenericExecutor {
  address public constant ONEINCH = AaveV2EthereumAssets.ONE_INCH_UNDERLYING;
  address public constant ENS = AaveV2EthereumAssets.ENS_UNDERLYING;
  address public constant LINK = AaveV2EthereumAssets.LINK_UNDERLYING;
  address public constant MKR = AaveV2EthereumAssets.MKR_UNDERLYING;
  address public constant SNX = AaveV2EthereumAssets.SNX_UNDERLYING;
  address public constant UNI = AaveV2EthereumAssets.UNI_UNDERLYING;


  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(ONEINCH);
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(ENS);
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(LINK);
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(MKR);
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(SNX);
    AaveV2Ethereum.POOL_CONFIGURATOR.freezeReserve(UNI);
  }
}