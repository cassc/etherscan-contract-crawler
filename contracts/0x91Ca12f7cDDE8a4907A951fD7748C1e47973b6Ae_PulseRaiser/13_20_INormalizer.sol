// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./INormalizerEvents.sol";

interface INormalizer is INormalizerEvents {
    // @dev Owner-only. Enable/disable whitelisted ERC20 assets (non-stables) that can be evaluated in USD via
    //      Chainlink price feeds.
    function controlAssetsWhitelisting(
        address[] memory tokens_,
        address[] memory feeds_
    ) external;

    // @dev Owner-only. Enable/disable whitelisted ERC20 stablecoins. 
    function controlStables(
        address[] memory stables_,
        bool[] memory states_
    ) external;
}