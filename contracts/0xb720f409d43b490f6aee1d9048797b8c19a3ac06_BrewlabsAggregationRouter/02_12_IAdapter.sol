// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdapter {
    function name() external view returns (string memory);

    function swapGasEstimate() external view returns (uint256);

    function swap(
        uint256,
        address,
        address,
        address
    ) external returns (uint256);

    function query(
        uint256,
        address,
        address
    ) external view returns (uint256);
}