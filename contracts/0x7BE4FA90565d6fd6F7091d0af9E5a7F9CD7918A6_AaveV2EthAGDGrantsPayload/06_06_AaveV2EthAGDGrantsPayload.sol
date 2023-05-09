// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title AaveV2EthAGDGrantsPayload
 * @author Llama
 * @dev Grant AGD approval to aUSDT v2 and revoke approval to aUSDT v1
 * Forum: https://governance.aave.com/t/updated-proposal-aave-grants-dao-renewal/11289
 * Communication: https://governance.aave.com/t/updated-proposal-aave-grants-dao-renewal/11289/9
 */
contract AaveV2EthAGDGrantsPayload is IProposalGenericExecutor {

  address public constant AGD_MULTISIG = 0x89C51828427F70D77875C6747759fB17Ba10Ceb0;
  address public constant aUSDTV1 = 0x71fc860F7D3A592A4a98740e39dB31d25db65ae8;
  uint256 public constant AMOUNT_AUSDT = 812_944_900000; // $812,944.90

  function execute() external {
    AaveV2Ethereum.COLLECTOR.approve(aUSDTV1, AGD_MULTISIG, 0);
    AaveV2Ethereum.COLLECTOR.approve(AaveV2EthereumAssets.USDT_A_TOKEN, AGD_MULTISIG, AMOUNT_AUSDT);
    }
}