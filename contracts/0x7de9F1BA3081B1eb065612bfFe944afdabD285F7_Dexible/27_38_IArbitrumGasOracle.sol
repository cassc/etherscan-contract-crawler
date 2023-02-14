//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IArbitrumGasOracle {
    function calculateGasCost(uint callDataSize, uint l2GasUsed) external view returns (uint);
}