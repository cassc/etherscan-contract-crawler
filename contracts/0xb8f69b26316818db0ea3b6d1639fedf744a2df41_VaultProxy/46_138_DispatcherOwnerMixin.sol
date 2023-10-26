// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../persistent/dispatcher/IDispatcher.sol";

/// @title DispatcherOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract that defers ownership to the owner of Dispatcher
abstract contract DispatcherOwnerMixin {
    address internal immutable DISPATCHER;

    modifier onlyDispatcherOwner() {
        require(
            msg.sender == getOwner(),
            "onlyDispatcherOwner: Only the Dispatcher owner can call this function"
        );
        _;
    }

    constructor(address _dispatcher) public {
        DISPATCHER = _dispatcher;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the Dispatcher contract
    function getOwner() public view returns (address owner_) {
        return IDispatcher(DISPATCHER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() external view returns (address dispatcher_) {
        return DISPATCHER;
    }
}