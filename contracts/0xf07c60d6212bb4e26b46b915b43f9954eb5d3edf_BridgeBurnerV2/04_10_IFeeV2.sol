// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IFeeV2 {
    function calculate(address sender, uint256 amount) external view returns (uint256);
}