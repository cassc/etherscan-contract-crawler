// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract IdleCDOFactory {
  event CDODeployed(address proxy);

  function deployCDO(address implementation, address admin, bytes memory data) public {
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(implementation, admin, data);
    emit CDODeployed(address(proxy));
  }
}