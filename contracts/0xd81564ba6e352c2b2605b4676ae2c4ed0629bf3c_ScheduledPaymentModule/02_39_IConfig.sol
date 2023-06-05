// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

interface IConfig {
    function crankAddress() external view returns (address);

    function feeReceiver() external view returns (address);

    function validForDays() external view returns (uint8);

    function validForSeconds() external view returns (uint256);
}