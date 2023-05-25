// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

interface ICalculator {
    function compute(bytes memory params) external view returns (uint256);
}