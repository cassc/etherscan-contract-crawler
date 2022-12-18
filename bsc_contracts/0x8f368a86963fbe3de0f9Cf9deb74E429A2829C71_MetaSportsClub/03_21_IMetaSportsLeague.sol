// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaSportsLeague {
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);
}