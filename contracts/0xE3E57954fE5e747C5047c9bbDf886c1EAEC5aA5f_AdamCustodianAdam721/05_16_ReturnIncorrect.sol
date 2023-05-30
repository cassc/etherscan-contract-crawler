// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;


abstract contract ReturnIncorrect {
    bytes32 public constant RETURNER_ROLE = keccak256("RETURNER_ROLE");
}