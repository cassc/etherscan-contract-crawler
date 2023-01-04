// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Controllable} from "./Controllable.sol";
import {IAllowList} from "../interfaces/IAllowList.sol";

/// @title AllowList - Tracks approved addresses
/// @notice An abstract contract for tracking allowed and denied addresses.
abstract contract AllowList is IAllowList, Controllable {
    mapping(address => bool) public allowed;

    modifier onlyAllowed() {
        if (!allowed[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc IAllowList
    function denied(address caller) external view returns (bool) {
        return !allowed[caller];
    }

    /// @inheritdoc IAllowList
    function allow(address caller) external onlyController {
        allowed[caller] = true;
        emit Allow(caller);
    }

    /// @inheritdoc IAllowList
    function deny(address caller) external onlyController {
        allowed[caller] = false;
        emit Deny(caller);
    }
}