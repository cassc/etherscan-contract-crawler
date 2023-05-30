// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./GridAddress.sol";

library CallbackValidator {
    /// @dev Validates the `msg.sender` is the canonical grid address for the given parameters
    /// @param gridFactory The address of the grid factory
    /// @param gridKey The grid key to compute the canonical address for the grid
    function validate(address gridFactory, GridAddress.GridKey memory gridKey) internal view {
        // CV_IC: invalid caller
        require(GridAddress.computeAddress(gridFactory, gridKey) == msg.sender, "CV_IC");
    }
}