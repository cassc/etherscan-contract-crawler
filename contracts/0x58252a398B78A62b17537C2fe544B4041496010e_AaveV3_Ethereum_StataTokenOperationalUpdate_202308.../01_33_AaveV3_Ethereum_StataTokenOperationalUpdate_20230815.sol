// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {IStaticATokenFactory} from './IStaticATokenFactory.sol';

/**
 * @title stataToken operational update
 * @author BGD labs
 * - Discussion: https://governance.aave.com/t/bgd-statatoken-operational-update/14497
 */
contract AaveV3_Ethereum_StataTokenOperationalUpdate_20230815 is IProposalGenericExecutor {
  address public constant NEW_ADMIN = 0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f;

  address public constant WAWETH = 0x59463BB67dDD04fe58ED291ba36C26d99A39fbc6;

  address public constant WAUSDT = 0xa7E0e66F38b8ad8343CFF67118C1f33e827D1455;

  address public constant WADAI = 0x098256c06ab24F5655C5506A6488781BD711c14b;

  address public constant WAUSDC = 0x57d20c946A7A3812a7225B881CdcD8431D23431C;

  function execute() external {
    address[] memory tokens = IStaticATokenFactory(AaveV3Ethereum.STATIC_A_TOKEN_FACTORY)
      .getStaticATokens();
    for (uint256 i; i < tokens.length; i++) {
      ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM).changeProxyAdmin(
        TransparentUpgradeableProxy(payable(tokens[i])),
        NEW_ADMIN
      );
    }
    TransparentUpgradeableProxy(payable(WAWETH)).changeAdmin(NEW_ADMIN);
    TransparentUpgradeableProxy(payable(WAUSDT)).changeAdmin(NEW_ADMIN);
    TransparentUpgradeableProxy(payable(WADAI)).changeAdmin(NEW_ADMIN);
    TransparentUpgradeableProxy(payable(WAUSDC)).changeAdmin(NEW_ADMIN);
  }
}