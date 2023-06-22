// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IVault {

    function savingsContract() external view returns (address);

    function musd() external view returns (address);

    function deposit(uint256) external;

    function redeem(uint256) external;

    function getBalance() external view returns (uint256);

}