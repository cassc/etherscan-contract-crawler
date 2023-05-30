// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IFraxMinter {
    function submitAndDeposit(address recipient) external payable;
}