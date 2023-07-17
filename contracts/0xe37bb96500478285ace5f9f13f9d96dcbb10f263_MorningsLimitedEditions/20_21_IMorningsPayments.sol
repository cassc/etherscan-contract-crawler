// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMorningsPayments {
    function releaseAllETH() external;

    function releaseAllToken(address tokenAddress) external;
}