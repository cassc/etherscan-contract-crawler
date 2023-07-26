// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {PauseStorage} from "./libraries/PauseStorage.sol";
import {PauseBase} from "./base/PauseBase.sol";
import {ContractOwnership} from "../access/ContractOwnership.sol";

/// @title Pausing mechanism (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
abstract contract Pause is PauseBase, ContractOwnership {
    using PauseStorage for PauseStorage.Layout;

    /// @notice Initializes the storage with an initial pause state.
    /// @dev Emits a {Paused} event if `isPaused` is true.
    /// @param isPaused The initial pause state.
    constructor(bool isPaused) {
        PauseStorage.layout().constructorInit(isPaused);
    }
}