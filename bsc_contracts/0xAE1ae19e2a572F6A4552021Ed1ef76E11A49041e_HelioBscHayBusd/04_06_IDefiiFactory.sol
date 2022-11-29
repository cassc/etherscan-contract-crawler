// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IDefiiFactory {
    function executor() view external returns (address executor);

    function createDefiiFor(address wallet) external;
    function createDefii() external;
    function getDefiiFor(address wallet) external view returns (address defii);
}