// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IWRAPPED {
    // brief interface for canonical native token wrapper contract
    function deposit() external payable;
}