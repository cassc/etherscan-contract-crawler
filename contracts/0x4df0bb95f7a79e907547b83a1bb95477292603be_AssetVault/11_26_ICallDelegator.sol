// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICallDelegator {
    // ============== View Functions ==============

    function canCallOn(address caller, address vault) external view returns (bool);
}