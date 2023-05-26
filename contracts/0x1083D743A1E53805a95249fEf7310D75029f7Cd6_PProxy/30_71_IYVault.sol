// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IYVault {
    function depositAll() external;
    function deposit(uint _amount) external;
    function withdraw(uint _shares) external;
    function getPricePerFullShare() external view returns (uint);
}