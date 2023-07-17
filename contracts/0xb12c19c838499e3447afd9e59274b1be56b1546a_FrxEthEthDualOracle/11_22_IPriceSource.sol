// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { IPriceSourceReceiver } from "./IPriceSourceReceiver.sol";

interface IPriceSource {
    function addRoundData(IPriceSourceReceiver fraxOracle) external;
}