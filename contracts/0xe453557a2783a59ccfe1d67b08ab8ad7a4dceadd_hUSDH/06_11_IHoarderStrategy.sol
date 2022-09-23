// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IHoarderStrategy {
    function init(address tokenDepositOld, uint256 amount) external;
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256);
    function end() external;
    function getStrategist() external view returns (address);
    function tokenDeposit() external view returns (address);
    function token() external view returns (address);
    function feeTier() external view returns (uint24);
    function name() external pure returns (string memory);
}