// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { Governable } from "./Governable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract InitializableGovernable is Initializable, Governable {
    function _initialize(address _gemGlobalConfig) internal initializer {
        _init(_gemGlobalConfig);
    }
}