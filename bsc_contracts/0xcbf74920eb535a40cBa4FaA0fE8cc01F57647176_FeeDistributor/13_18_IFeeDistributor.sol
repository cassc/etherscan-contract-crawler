// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IFeeDistributor {
    function emitFeeCollection(uint256 amount) external;
}