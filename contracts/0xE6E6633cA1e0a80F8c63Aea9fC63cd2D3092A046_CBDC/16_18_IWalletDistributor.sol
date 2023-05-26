// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWalletDistributor {
    function receiveToken(address token, address from, uint256 amount) external;
}