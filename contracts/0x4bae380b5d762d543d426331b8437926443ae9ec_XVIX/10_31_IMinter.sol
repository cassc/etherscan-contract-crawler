// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMinter {
    function enableMint(uint256 ethReserve) external;
}