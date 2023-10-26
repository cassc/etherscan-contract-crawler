// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';

/**
 * @title ACI Phase II
 * @author Marc Zeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x04e7059fc5b2c33d4e4554d68d27ef67c1f6d9d310b07493116bdfbf15c25bbc
 * - Discussion: https://governance.aave.com/t/arfc-aci-phase-ii/15138
 */
contract AaveV3_Ethereum_ACIPhaseII_20231022 is IProposalGenericExecutor {
  address public constant ACI_TREASURY = 0x57ab7ee15cE5ECacB1aB84EE42D5A9d0d8112922;
  address public constant GHO = AaveV3EthereumAssets.GHO_UNDERLYING;
  uint256 public constant STREAM_AMOUNT = 375_000 ether;
  uint256 public constant STREAM_DURATION = 180 days;
  uint256 public constant ACTUAL_STREAM_AMOUNT_GHO =
    (STREAM_AMOUNT / STREAM_DURATION) * STREAM_DURATION;

  function execute() external {
    AaveV3Ethereum.COLLECTOR.createStream(
      ACI_TREASURY,
      ACTUAL_STREAM_AMOUNT_GHO,
      GHO,
      block.timestamp,
      block.timestamp + STREAM_DURATION
    );
  }
}