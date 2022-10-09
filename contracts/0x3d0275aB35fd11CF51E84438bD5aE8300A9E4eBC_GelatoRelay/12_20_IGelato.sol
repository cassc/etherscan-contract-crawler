// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IGelato {
    function getFeeCollector() external view returns (address feeCollector);
}