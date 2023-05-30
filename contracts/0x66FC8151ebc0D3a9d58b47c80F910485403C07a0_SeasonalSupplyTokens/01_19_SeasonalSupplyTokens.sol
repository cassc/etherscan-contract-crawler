// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./BaseTokens.sol";

contract SeasonalSupplyTokens is BaseTokens {
    /// @dev The limit number of cards that can be minted depending on their Season.
    mapping(uint16 => uint256) public seasonSupply;

    constructor(
        string memory name,
        string memory symbol,
        address relayAddress
    ) BaseTokens(name, symbol, relayAddress) {}

    /// @dev Init the maximum number of cards that can be created for a season.
    function setSeasonSupply(uint16 season, uint256 supply) public onlyOwner {
        require(seasonSupply[season] == 0, "Season supply already set");

        seasonSupply[season] = supply;
    }

    function _getScarcityLimit(uint16 season, uint8 scarcity)
        internal
        view
        override
        returns (uint256)
    {
        if (scarcity != 0) return 0;

        return seasonSupply[season];
    }
}