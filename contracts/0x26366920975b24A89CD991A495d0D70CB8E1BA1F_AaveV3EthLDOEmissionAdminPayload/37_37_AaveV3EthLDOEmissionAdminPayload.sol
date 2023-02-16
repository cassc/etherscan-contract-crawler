// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import 'forge-std/Test.sol';

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {IEmissionManager} from 'aave-v3-periphery/rewards/interfaces/IEmissionManager.sol';

/**
 * @title AaveV3EthLDOEmissionAdminPayload
 * @author Llama
 * @dev Setting new Emssion Admin for LDO token in Aave V3 Ethereum Liquidity Pool
 * Governance Forum Post: https://governance.aave.com/t/arfc-ldo-emission-admin-for-ethereum-arbitrum-and-optimism-v3-liquidity-pools/11478
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xc28c45bf26a5ada3d891a5dbed7f76d1ff0444b9bc06d191a6ada99a658abe28
 */
contract AaveV3EthLDOEmissionAdminPayload is IProposalGenericExecutor {
  address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
  address public constant NEW_EMISSION_ADMIN = 0x87D93d9B2C672bf9c9642d853a8682546a5012B5;

  function execute() public {
    IEmissionManager(AaveV3Ethereum.EMISSION_MANAGER).setEmissionAdmin(LDO, NEW_EMISSION_ADMIN);
  }
}