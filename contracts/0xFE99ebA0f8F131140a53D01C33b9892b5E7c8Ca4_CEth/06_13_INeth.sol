// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INeth {
    function getPresentValueUnderlyingDenominated() external view returns (int256);
}