// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title ChaosLabs Service Provider Payment Collection
 * @author @yonikesel - ChaosLabs
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xad105e87d4df487bbe1daec2cd94ca49d1ea595901f5773c1804107539288b59
 * - Discussion: https://governance.aave.com/t/arfc-chaos-labs-payment-collection-request/13792
 */
contract AaveV3ChaosLabsPaymentCollection_20230626 is IProposalGenericExecutor {
  address public constant CHAOS_LABS = 0xbC540e0729B732fb14afA240aA5A047aE9ba7dF0;
  uint256 public constant PAYMENT_AMOUNT = 6541e18;

  function execute() external {
    AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.transfer(
      AaveMisc.ECOSYSTEM_RESERVE,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      CHAOS_LABS,
      PAYMENT_AMOUNT
    );
  }
}