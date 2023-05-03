//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface ITokenB {
    function pairAddress() external view returns (address);
    function sync() external;
}