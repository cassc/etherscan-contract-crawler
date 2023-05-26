// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICToken {
    function admin() external view returns (address);
    function symbol() external view returns (string memory);
    function underlying() external view returns (address);
    function totalReserves() external view returns (uint);
}