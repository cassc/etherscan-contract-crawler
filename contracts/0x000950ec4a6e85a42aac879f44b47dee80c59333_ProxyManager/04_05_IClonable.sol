// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IClonable {
    function init(bytes memory data) external payable;
}