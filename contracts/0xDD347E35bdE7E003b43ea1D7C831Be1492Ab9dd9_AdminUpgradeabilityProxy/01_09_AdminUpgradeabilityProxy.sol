// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract AdminUpgradeabilityProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) payable TransparentUpgradeableProxy(logic, admin, data) {}
}