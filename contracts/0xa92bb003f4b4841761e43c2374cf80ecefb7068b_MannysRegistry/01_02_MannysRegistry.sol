// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import {Owned} from "solmate/auth/Owned.sol";

interface IMannysGame {
    function ownerOf(uint256 tokenId) external view returns (address);

    function tokensByOwner(address owner)
        external
        view
        returns (uint16[] memory);
}

contract MannysRegistry is Owned {
    // official mannys.game contract
    IMannysGame MannysGame =
        IMannysGame(0x2bd58A19C7E4AbF17638c5eE6fA96EE5EB53aed9);

    // storage for preferred mannys
    mapping(address => uint256) private registry;

    // storage for rarity points set by manny
    mapping(uint256 => uint256) private mannySortPointsPoints;

    event MannyPreferenceUpdated(
        address indexed owner,
        uint256 indexed tokenId
    );
    error MannyNotOwned();

    // set initial rarity points on deploy
    constructor(uint16[] memory tokenIds, uint16[] memory points)
        Owned(msg.sender)
    {
        // Set initial scores in the points registry
        // Based on scores at deploy time from https://github.com/mannynotfound/mannys-game/blob/db30c7069f11033e36e4d38d34754ea14741a245/src/utils.js
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mannySortPointsPoints[tokenIds[i]] = points[i];
        }
    }

    // use this to set your preferred manny
    // only works for mannys you own
    function setPreferredManny(uint256 tokenId) external {
        if (MannysGame.ownerOf(tokenId) != msg.sender) revert MannyNotOwned();

        registry[msg.sender] = tokenId;
        emit MannyPreferenceUpdated(msg.sender, tokenId);
    }

    // returns the preferred manny for an address
    // if a manny hasn't been manually set, it'll return the rarest manny from that owner
    // if a manny was set previously but is no longer owned, it'll return the rarest manny from that owner
    // if the owner has no mannys, it'll revert
    function getPreferredManny(address gamer) external view returns (uint256) {
        uint256 tokenId = registry[gamer];
        if (tokenId != 0 && MannysGame.ownerOf(tokenId) == gamer) {
            return registry[gamer];
        } else {
            uint16[] memory tokenIds = MannysGame.tokensByOwner(gamer);
            if (tokenIds.length > 0) return findRarestManny(tokenIds);
            else revert MannyNotOwned();
        }
    }

    // returns the rarest manny from a set
    function findRarestManny(uint16[] memory tokens)
        internal
        view
        returns (uint256)
    {
        uint256 bestManny = tokens[0];
        uint256 bestPoints;
        for (uint256 i; i < tokens.length; i++) {
            uint256 points = mannySortPointsPoints[tokens[i]];
            if (points > bestPoints) {
                bestPoints = points;
                bestManny = tokens[i];
            } else if (points == bestPoints) {
                if (tokens[i] < bestManny) {
                    bestManny = tokens[i];
                }
            }
        }
        return bestManny;
    }

    // lets the owner adjust the manny points
    function updateMannyPoints(
        uint256[] memory tokenIds,
        uint256[] memory points
    ) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            mannySortPointsPoints[tokenIds[i]] = points[i];
        }
    }
}