// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


abstract contract HasAuthorization {

    /// sender is not authorized for this action
    error Unauthorized();

    modifier only(address authorized) { if (msg.sender != authorized) revert Unauthorized(); _; }
}