// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBaseCollection {
    function withdraw() external;

    function setTreasury(address newTreasury) external;

    function treasury() external view returns (address);
}