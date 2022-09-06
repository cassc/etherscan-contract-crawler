// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from "../Types.sol";

interface IAmplifiNode {
    function amplifiers(uint256) external view returns (Types.Amplifier memory);
}