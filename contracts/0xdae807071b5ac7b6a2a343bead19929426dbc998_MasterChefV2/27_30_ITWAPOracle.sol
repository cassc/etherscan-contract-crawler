// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITWAPOracle {
    function update() external;

    function consult(address token) external view returns (uint256 amountOut);
}