// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IYDT {
    function isAdmin(address _user) external view returns (bool);
}