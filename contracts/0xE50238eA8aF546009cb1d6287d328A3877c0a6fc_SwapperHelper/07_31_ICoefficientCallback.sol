// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICoefficientCallback {
    function calculateCoefficientX96() external view returns (uint256);
}