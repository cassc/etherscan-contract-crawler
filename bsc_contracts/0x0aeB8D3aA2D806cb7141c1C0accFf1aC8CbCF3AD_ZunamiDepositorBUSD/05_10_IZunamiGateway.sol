//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZunamiGateway {
    function delegateDepositFor(address beneficiary, uint256 amount) external;
}