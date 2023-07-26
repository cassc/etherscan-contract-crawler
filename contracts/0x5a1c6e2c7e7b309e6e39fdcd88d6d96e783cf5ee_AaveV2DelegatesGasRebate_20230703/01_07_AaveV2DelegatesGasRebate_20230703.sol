// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title Gas Rebate for Delegates platforms
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xff11b348c1e8df41555d7579c7785942378bcf09ff1d9ca97af1d86b2b124beb
 * - Discussion: https://governance.aave.com/t/arfc-gas-rebate-for-recognized-delegates/13290
 */
contract AaveV2DelegatesGasRebate_20230703 is IProposalGenericExecutor {
  address public constant ACI = 0x329c54289Ff5D6B7b7daE13592C6B1EDA1543eD4;
  address public constant ACI_DEPLOY = 0x3Cbded22F878aFC8d39dCD744d3Fe62086B76193;
  address public constant FLIPSIDE = 0x62a43123FE71f9764f26554b3F5017627996816a;
  address public constant TOKEN_LOGIC = 0xA06c2e5BB33cd6718b08EC9335081Cbba62861f7;
  address public constant MICHIGAN = 0x13BDaE8c5F0fC40231F0E6A4ad70196F59138548;
  address public constant LBS = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
  address public constant WINTERMUTE = 0xB933AEe47C438f22DE0747D57fc239FE37878Dd1;
  address public constant KEYROCK = 0x1855f41B8A86e701E33199DE7C25d3e3830698ba;
  address public constant STABLELAB = 0xea172676E4105e92Cc52DBf45fD93b274eC96676;
  uint256 public constant ACI_AMOUNT = 0.95e18;
  uint256 public constant ACI_DEPLOY_AMOUNT = 0.33e18;
  uint256 public constant FLIPSIDE_AMOUNT = 0.38e18;
  uint256 public constant TOKEN_LOGIC_AMOUNT = 0.21e18;
  uint256 public constant MICHIGAN_AMOUNT = 0.21e18;
  uint256 public constant LBS_AMOUNT = 0.26e18;
  uint256 public constant WINTERMUTE_AMOUNT = 0.19e18;
  uint256 public constant KEYROCK_AMOUNT = 0.16e18;
  uint256 public constant STABLELAB_AMOUNT = 0.29e18;

  function execute() external {
    AaveV2Ethereum.COLLECTOR.transfer(AaveV2EthereumAssets.WETH_UNDERLYING, ACI, ACI_AMOUNT);
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      ACI_DEPLOY,
      ACI_DEPLOY_AMOUNT
    );
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      FLIPSIDE,
      FLIPSIDE_AMOUNT
    );
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      TOKEN_LOGIC,
      TOKEN_LOGIC_AMOUNT
    );
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      MICHIGAN,
      MICHIGAN_AMOUNT
    );
    AaveV2Ethereum.COLLECTOR.transfer(AaveV2EthereumAssets.WETH_UNDERLYING, LBS, LBS_AMOUNT);
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      WINTERMUTE,
      WINTERMUTE_AMOUNT
    );
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      KEYROCK,
      KEYROCK_AMOUNT
    );
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.WETH_UNDERLYING,
      STABLELAB,
      STABLELAB_AMOUNT
    );
  }
}