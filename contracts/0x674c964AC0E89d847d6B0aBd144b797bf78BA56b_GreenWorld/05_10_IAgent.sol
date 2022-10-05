// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgent {
    function increaseStock(uint256 amount) external;

    function autoLiquidity() external;

    function getStock() external view returns (uint256);

    function getThreshold() external view returns (uint256);
}