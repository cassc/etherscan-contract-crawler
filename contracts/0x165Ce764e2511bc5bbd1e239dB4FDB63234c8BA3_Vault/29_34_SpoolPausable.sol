// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../interfaces/IController.sol";

/// @title Facilitates checking if the system is paused or not
abstract contract SpoolPausable {
    /* ========== STATE VARIABLES ========== */

    /// @notice The controller contract that is consulted for a strategy's and vault's validity
    IController public immutable controller;

    /**
     * @notice Sets initial values
     * @param _controller Controller contract address
     */
    constructor(IController _controller) {
        require(
            address(_controller) != address(0),
            "SpoolPausable::constructor: Controller contract address cannot be 0"
        );

        controller = _controller;
    }

    /* ========== MODIFIERS ========== */

    /// @notice Throws if system is paused
    modifier systemNotPaused() {
        controller.checkPaused();
        _;
    }
}