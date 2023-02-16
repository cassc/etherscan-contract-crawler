//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IStandardGasAdjustments {

    function adjustment(string memory adjType) external view returns (uint);
}