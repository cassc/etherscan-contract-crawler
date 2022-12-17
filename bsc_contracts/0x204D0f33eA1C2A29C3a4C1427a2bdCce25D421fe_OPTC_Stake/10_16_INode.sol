// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface INode {
    function syncDebt(uint amount) external;

    function minInitNode(address addr) external;
    function syncSuperDebt(uint amount) external;
}