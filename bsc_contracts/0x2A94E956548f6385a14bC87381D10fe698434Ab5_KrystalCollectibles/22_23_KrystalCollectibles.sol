// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./KrystalCollectiblesStorage.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract KrystalCollectibles is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {}
}