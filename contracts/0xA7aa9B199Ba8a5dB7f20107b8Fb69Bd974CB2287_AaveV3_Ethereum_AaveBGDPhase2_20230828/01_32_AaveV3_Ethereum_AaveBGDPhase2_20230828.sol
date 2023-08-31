// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';

/**
 * @title Aave BGD Phase 2
 * @notice Approval for BGD Labs to engage for service with the Aave DAO, creating the defined payments
 * @author BGD Labs @bgdlabs
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xe72dd00eb1ab6223b87e5e1fa740c39b64bfef9b7ccb0939e53403c78a04b18e
 * - Discussion: https://governance.aave.com/t/aave-bored-ghosts-developing-phase-2/14484
 */
contract AaveV3_Ethereum_AaveBGDPhase2_20230828 is IProposalGenericExecutor {
  using SafeERC20 for IERC20;

  address public constant BGD_RECIPIENT = 0xb812d0944f8F581DfAA3a93Dda0d22EcEf51A9CF;

  uint256 public constant STREAMS_DURATION = 180 days;

  uint256 public constant ADAI_UPFRONT_AMOUNT = 1_140_000 ether;
  uint256 public constant ADAI_STREAM_AMOUNT = 760_000 ether;
  uint256 public constant ACTUAL_STREAM_AMOUNT_ADAI =
    (ADAI_STREAM_AMOUNT / STREAMS_DURATION) * STREAMS_DURATION;

  uint256 public constant AAVE_UPFRONT_AMOUNT = 3_600 ether;
  uint256 public constant AAVE_STREAM_AMOUNT = 2_400 ether;
  uint256 public constant ACTUAL_STREAM_AMOUNT_AAVE =
    (AAVE_STREAM_AMOUNT / STREAMS_DURATION) * STREAMS_DURATION;

  function execute() external {
    // ---
    // 1. Upfront payments (aDAI v2 and AAVE)
    // ---

    AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.transfer(
      AaveMisc.ECOSYSTEM_RESERVE,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      BGD_RECIPIENT,
      AAVE_UPFRONT_AMOUNT
    );

    AaveV3Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.DAI_A_TOKEN,
      BGD_RECIPIENT,
      ADAI_UPFRONT_AMOUNT
    );

    // ---
    // 2. Migrate Collector's aDAI v2 -> aDAI v3
    // ---

    uint256 collectorADAIBalance = IERC20(AaveV2EthereumAssets.DAI_A_TOKEN).balanceOf(
      address(AaveV2Ethereum.COLLECTOR)
    );

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.DAI_A_TOKEN,
      address(this),
      collectorADAIBalance
    );

    AaveV2Ethereum.POOL.withdraw(
      AaveV2EthereumAssets.DAI_UNDERLYING,
      type(uint256).max,
      address(this)
    );

    uint256 executorDAIBalance = IERC20(AaveV3EthereumAssets.DAI_UNDERLYING).balanceOf(
      address(this)
    );

    IERC20(AaveV3EthereumAssets.DAI_UNDERLYING).forceApprove(
      address(AaveV3Ethereum.POOL),
      executorDAIBalance
    );
    AaveV3Ethereum.POOL.supply(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      executorDAIBalance,
      address(AaveV3Ethereum.COLLECTOR),
      0
    );

    // ---
    // 3. Streams creation (aDAI v3 and AAVE)
    // ---

    AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.createStream(
      AaveMisc.ECOSYSTEM_RESERVE,
      BGD_RECIPIENT,
      ACTUAL_STREAM_AMOUNT_AAVE,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      block.timestamp,
      block.timestamp + STREAMS_DURATION
    );

    AaveV3Ethereum.COLLECTOR.createStream(
      BGD_RECIPIENT,
      ACTUAL_STREAM_AMOUNT_ADAI,
      AaveV3EthereumAssets.DAI_A_TOKEN,
      block.timestamp,
      block.timestamp + STREAMS_DURATION
    );
  }
}