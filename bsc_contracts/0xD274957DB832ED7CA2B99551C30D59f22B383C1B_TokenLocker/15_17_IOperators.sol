// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOperators {
    function isOper(address) external view returns (bool);

    function setOper(address _a, bool _b) external;
}