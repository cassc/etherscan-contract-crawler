/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IRcaController {
    function activeShields(address shield) external view returns (bool);
}