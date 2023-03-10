// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IWaterfallModule} from "./IWaterfallModule.sol";

interface IWaterfallModuleFactory {
    function createWaterfallModule(
        address token,
        address nonWaterfallRecipient,
        address[] calldata recipients,
        uint256[] calldata thresholds
    ) external returns (IWaterfallModule); // Should this be address?
}