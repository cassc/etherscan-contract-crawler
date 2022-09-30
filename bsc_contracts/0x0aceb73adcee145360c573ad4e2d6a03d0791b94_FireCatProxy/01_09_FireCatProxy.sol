// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FireCatProxy is TransparentUpgradeableProxy {
    constructor(address _logic,address _admin,bytes memory _data) TransparentUpgradeableProxy(_logic, _admin, _data){}
}