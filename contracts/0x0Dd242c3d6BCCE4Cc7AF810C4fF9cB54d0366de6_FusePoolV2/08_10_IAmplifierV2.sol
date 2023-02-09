// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from "../Types.sol";

interface IAmplifierV2 {
    function amplifiers(uint256) external view returns (Types.AmplifierV2 memory);
}