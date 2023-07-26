// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IMilkman} from './interfaces/IMilkman.sol';

import {COWTrader} from './COWTrader.sol';

/**
 * @title Acquire B-80BAL-20WETH BPT
 * @author Llama
 * @dev This proposal swaps BAL, aBAL, aEthBAL and wETH tokens held by the collector for B-80BAL-20WETH
 * Governance: https://governance.aave.com/t/deploy-bal-abal-from-the-collector-contract/9747
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x05182d6092e7a075b94ab937a6cd57968f36c6ac225196561a58b437e591065f
 */
contract SwapFor80BAL20WETHPayload is IProposalGenericExecutor {
  uint256 public constant WETH_AMOUNT = 326_88e16; // 326.88 aWETH

  function execute() external {
    /*******************************************************************************
     ********************************* New Trader **********************************
     *******************************************************************************/

    COWTrader trader = new COWTrader();

    /*******************************************************************************
     ******************************* Withdraw aTokens *******************************
     *******************************************************************************/

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_A_TOKEN,
      address(this),
      WETH_AMOUNT
    );

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.BAL_A_TOKEN,
      address(this),
      IERC20(AaveV2EthereumAssets.BAL_A_TOKEN).balanceOf(address(AaveV2Ethereum.COLLECTOR))
    );

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV3EthereumAssets.BAL_A_TOKEN,
      address(this),
      IERC20(AaveV3EthereumAssets.BAL_A_TOKEN).balanceOf(address(AaveV2Ethereum.COLLECTOR))
    );

    AaveV2Ethereum.POOL.withdraw(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      type(uint256).max,
      address(trader)
    );

    AaveV2Ethereum.POOL.withdraw(
      AaveV2EthereumAssets.BAL_UNDERLYING,
      type(uint256).max,
      address(trader)
    );

    AaveV3Ethereum.POOL.withdraw(
      AaveV3EthereumAssets.BAL_UNDERLYING,
      type(uint256).max,
      address(trader)
    );

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.BAL_UNDERLYING,
      address(trader),
      IERC20(AaveV2EthereumAssets.BAL_UNDERLYING).balanceOf(address(AaveV2Ethereum.COLLECTOR))
    );

    /*******************************************************************************
     *********************************** Trade *************************************
     *******************************************************************************/

    trader.trade();
  }
}