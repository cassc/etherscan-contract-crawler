// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IStrategy {
    function want() external view returns (address);

    function farmingToken() external view returns (address);

    function inFarmBalance() external view returns (uint256);

    function totalBalance() external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function withdrawAll() external;

    function emergencyWithdraw() external;
}