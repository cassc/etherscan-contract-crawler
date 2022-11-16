// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INusdc {
    function getPresentValueUnderlyingDenominated() external view returns (int256);
}