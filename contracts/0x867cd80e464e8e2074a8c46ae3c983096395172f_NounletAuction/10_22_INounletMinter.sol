// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule, Permission} from "./IModule.sol";

/// @dev Interface for NounletMinter contract
interface INounletMinter is IModule {
    function supply() external view returns (address);
}