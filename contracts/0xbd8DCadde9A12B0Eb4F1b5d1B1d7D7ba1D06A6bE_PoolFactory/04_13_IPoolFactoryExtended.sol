// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import {SwapLib, ChainlinkLib} from "../lib/Lib.sol";

interface IPoolFactoryExtended {
    function createLinkFeedWithApiPool(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting calldata _dexSettings,
        SwapLib.FeedInfo calldata _stableFeedInfo
    ) external returns (address);
}