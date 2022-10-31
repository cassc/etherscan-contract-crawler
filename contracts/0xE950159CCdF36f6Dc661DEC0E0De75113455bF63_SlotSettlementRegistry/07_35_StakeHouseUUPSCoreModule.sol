// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ModuleGuards } from "./ModuleGuards.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { StakeHouseAccessControls } from "./StakeHouseAccessControls.sol";

abstract contract StakeHouseUUPSCoreModule is UUPSUpgradeable, ModuleGuards {
    function __StakeHouseUUPSCoreModule_init(StakeHouseUniverse _universe) internal {
        __initModuleGuards(_universe);
        __UUPSUpgradeable_init();
    }

    // address param is address of new implementation
    function _authorizeUpgrade(address) internal view override {
        require(address(universe) != address(0), "Init Err");
        StakeHouseAccessControls accessControls = universe.accessControls();
        require(!accessControls.isCoreModuleLocked(address(this)) && accessControls.isProxyAdmin(msg.sender), "Only mutable");
    }
}