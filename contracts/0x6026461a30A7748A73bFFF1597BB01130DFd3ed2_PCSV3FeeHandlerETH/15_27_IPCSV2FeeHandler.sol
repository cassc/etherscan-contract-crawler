// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPCSV2FeeHandler {
    function cakeBurnAddress() external view returns (address);
    function cakeVaultAddress() external view returns (address);
    function cake() external view returns (address);
    function operatorTopUpLimit() external view returns (uint);
}