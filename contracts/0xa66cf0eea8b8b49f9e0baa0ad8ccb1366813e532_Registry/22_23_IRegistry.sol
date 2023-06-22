// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

interface IRegistry {
    struct RoyaltyCollector {
        address collector;
        uint256 royaltyFee;
    }

    function createEvent(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256[] memory amounts,
        uint256[] memory prices,
        uint256 endTimestamp,
        RoyaltyCollector[] memory sellRoyaltyCollectors,
        RoyaltyCollector[] memory resellRoyaltyCollectors,
		uint256 ticketsLimitPerWallet
    ) external;
}