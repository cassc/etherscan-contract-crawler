// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IDelegation {
    function clearDelegate(bytes32 id) external;

    function setDelegate(bytes32 id, address delegate) external;

    function delegation(address delegator, bytes32 id)
        external
        view
        returns (address);
}