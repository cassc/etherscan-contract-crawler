// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IDorado {
    function viewSigner() external view returns (address);

    function viewWithdraw() external view returns (address);

    function getFeeRateOf(address collection) external view returns (uint16);
}