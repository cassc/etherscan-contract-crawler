// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IAugustusSwapperV5 {
    function hasRole(bytes32 role, address account) external view returns (bool);
}