// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IRDNRegistry} from "./IRDNRegistry.sol";

interface IRDNFactors {

    function getFactor(IRDNRegistry.User memory user) external view returns(uint);

    function calc(IRDNRegistry.User memory user) external pure returns(uint);

    function getDecimals() external view returns(uint);
}