// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUser {
    function getRef(address account) external view returns (address);
}