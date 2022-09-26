// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAlpacaToken {
    function canUnlockAmount(address _account) external view returns (uint256);

    function unlock() external;
}