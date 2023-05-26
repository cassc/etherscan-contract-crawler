// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "TransparentUpgradeableProxy.sol";

contract DfxUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {}

    function getAdmin() public view returns (address) {
        return _getAdmin();
    }
}