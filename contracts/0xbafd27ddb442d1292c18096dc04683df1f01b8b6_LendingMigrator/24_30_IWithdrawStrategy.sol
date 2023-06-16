// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IWithdrawStrategy {
    function withdrawApeCoin(uint256 required) external returns (uint256 withdrawn);
}