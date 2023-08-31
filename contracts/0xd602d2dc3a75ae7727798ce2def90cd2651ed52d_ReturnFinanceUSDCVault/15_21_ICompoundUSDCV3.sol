// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICompoundUSDCV3 {
    function allow(address who, bool status) external;

    function supply(address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;

    function withdrawTo(address to, address asset, uint amount) external;
}