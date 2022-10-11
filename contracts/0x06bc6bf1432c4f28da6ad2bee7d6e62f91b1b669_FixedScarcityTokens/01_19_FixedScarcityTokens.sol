// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./BaseTokens.sol";

contract FixedScarcityTokens is BaseTokens {
    /// @dev The limit number of cards that can be minted depending on their Scarcity Level.
    uint256[] public scarcityLimitByLevel;

    constructor(
        string memory name,
        string memory symbol,
        address relayAddress
    ) BaseTokens(name, symbol, relayAddress) {
        scarcityLimitByLevel.push(1);
    }

    /// @dev Init the maximum number of cards that can be created for a scarcity level.
    function setScarcityLimit(uint256 limit) public onlyOwner {
        uint256 editedScarcities = scarcityLimitByLevel.length - 1;
        require(
            limit >= scarcityLimitByLevel[editedScarcities] * 2,
            "Limit not large enough"
        );

        scarcityLimitByLevel.push(limit);
    }

    function _getScarcityLimit(uint16, uint8 scarcity)
        internal
        view
        override
        returns (uint256)
    {
        return scarcityLimitByLevel[scarcity];
    }
}