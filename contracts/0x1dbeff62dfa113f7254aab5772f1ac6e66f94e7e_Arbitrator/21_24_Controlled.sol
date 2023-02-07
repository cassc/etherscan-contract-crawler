// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {Owned} from "src/utils/Owned.sol";

/// @notice Authorization mixin that extends Owned with Controller rol.
abstract contract Controlled is Owned {
    /// @notice Raised when the control is transferred.
    /// @param user Address of the user that transferred the control.
    /// @param newController Address of the new controller.
    event ControlTransferred(address indexed user, address indexed newController);

    /// @notice Address that controls the contract.
    address public controller;

    modifier onlyController() virtual {
        if (msg.sender != controller) revert Unauthorized();

        _;
    }

    modifier onlyOwnerOrController() virtual {
        if (msg.sender != owner && msg.sender != controller) revert Unauthorized();

        _;
    }

    constructor(address owner_, address controller_) Owned(owner_) {
        controller = controller_;

        emit ControlTransferred(msg.sender, controller_);
    }

    /// @notice Transfer the control of the contract.
    /// @param newController Address of the new controller.
    function transferController(address newController) public virtual onlyOwner {
        controller = newController;

        emit ControlTransferred(msg.sender, newController);
    }
}