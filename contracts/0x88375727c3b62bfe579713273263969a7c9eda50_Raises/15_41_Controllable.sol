// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "../interfaces/IControllable.sol";

/// @title Controllable - Controller management functions
/// @notice An abstract base contract for contracts managed by the Controller.
abstract contract Controllable is IControllable {
    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) {
        if (_controller == address(0)) {
            revert ZeroAddress();
        }
        controller = _controller;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address) external virtual onlyController {
        revert InvalidDependency(_name);
    }
}