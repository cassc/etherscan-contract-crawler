// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title [ARFC] BUSD Offboarding Plan
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xe2393893421edc01915de463cbf517086c1f6a4e84f54fdba2ed163334178a2f
 * - Discussion: https://governance.aave.com/t/arfc-busd-offboarding-plan-part-ii/13048
 */
contract AaveV2EthBUSDIR_20230602 is IProposalGenericExecutor {
  address public constant INTEREST_RATE_STRATEGY = 0xB28cA2760001c9837430F20c50fD89Ed56A449f0;

  function execute() external {
    AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
      AaveV2EthereumAssets.BUSD_UNDERLYING,
      INTEREST_RATE_STRATEGY
    );

    uint256 aBUSDBalance = IERC20(AaveV2EthereumAssets.BUSD_A_TOKEN).balanceOf(
      address(AaveV2Ethereum.COLLECTOR)
    );
    uint256 availableBUSD = IERC20(AaveV2EthereumAssets.BUSD_UNDERLYING).balanceOf(
      AaveV2EthereumAssets.BUSD_A_TOKEN
    );
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.BUSD_A_TOKEN,
      address(this),
      aBUSDBalance > availableBUSD ? availableBUSD : aBUSDBalance
    );
    AaveV2Ethereum.POOL.withdraw(
      AaveV2EthereumAssets.BUSD_UNDERLYING,
      type(uint256).max,
      address(AaveV2Ethereum.COLLECTOR)
    );
  }
}