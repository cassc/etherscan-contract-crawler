// SPDX-License-Identifier: GPL-3.0

/// @title IOwnable interface

pragma solidity ^0.8.6;

interface IOwnable {
    function owner() external returns (address);
}