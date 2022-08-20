// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IRegistry} from "./IRegistry.sol";

interface IGaugeV2UniV3 {
    function registry() external view returns (IRegistry);
}