// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { BadgerBridgeZeroControllerMatic } from "../controllers/BadgerBridgeZeroControllerMatic.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

contract BadgerBridgeZeroControllerDeployer {
  address constant governance = 0x4A423AB37d70c00e8faA375fEcC4577e3b376aCa;
  event Deployment(address indexed proxy);

  constructor() {
    address logic = address(new BadgerBridgeZeroControllerMatic());
    ProxyAdmin proxy = new ProxyAdmin();
    ProxyAdmin(proxy).transferOwnership(governance);
    emit Deployment(
      address(
        new TransparentUpgradeableProxy(
          logic,
          address(proxy),
          abi.encodeWithSelector(BadgerBridgeZeroControllerMatic.initialize.selector, governance, governance)
        )
      )
    );
    selfdestruct(msg.sender);
  }
}