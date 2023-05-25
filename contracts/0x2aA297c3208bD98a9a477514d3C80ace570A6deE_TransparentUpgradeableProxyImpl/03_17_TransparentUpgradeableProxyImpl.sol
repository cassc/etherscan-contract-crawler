pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/proxy/TransparentUpgradeableProxy.sol';

contract TransparentUpgradeableProxyImpl is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}