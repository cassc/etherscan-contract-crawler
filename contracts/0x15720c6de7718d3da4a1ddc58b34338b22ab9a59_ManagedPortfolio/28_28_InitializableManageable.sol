// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Initializable} from "Initializable.sol";
import {UUPSUpgradeable} from "UUPSUpgradeable.sol";
import {Manageable} from "Manageable.sol";

abstract contract InitializableManageable is UUPSUpgradeable, Manageable, Initializable {
    constructor(address _manager) Manageable(_manager) initializer {}

    function initialize(address _manager) internal initializer {
        _setManager(_manager);
    }

    function _authorizeUpgrade(address) internal override onlyManager {}
}