//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStableConverter {
    function handle(
        address from,
        address to,
        uint256 amount,
        uint256 slippage
    ) external;

    function valuate(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);
}