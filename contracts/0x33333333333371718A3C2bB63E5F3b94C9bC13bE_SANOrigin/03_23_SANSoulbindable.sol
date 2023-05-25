//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title SANSoulbindable
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
interface SANSoulbindable {
    enum SoulboundLevel { Unbound, One, Two, Three, Four }

    event SoulBound(
        address indexed soulAccount,
        uint256 indexed tokenID,
        SoulboundLevel indexed newLevel,
        SoulboundLevel previousLevel
    );

    event SoulbindingEnabled(
        bool isEnabled
    );

    error CannotApproveSoulboundToken();
    error CannotTransferSoulboundToken();
    error InvalidNumberOfLevelPrices();
    error InvalidSoulbindCredit();
    error SoulbindingDisabled();
    error LevelAlreadyReached();
    error LevelFourFull();
    error LevelPricesNotIncreasing();
}