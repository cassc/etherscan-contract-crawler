// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ASCUpgradableProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {}

    function getAdmin() public view returns (address) {
        return _getAdmin();
    }
}