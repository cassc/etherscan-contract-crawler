// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IL2GasOracle {
    function l2BaseFee() external view returns(uint256);
}