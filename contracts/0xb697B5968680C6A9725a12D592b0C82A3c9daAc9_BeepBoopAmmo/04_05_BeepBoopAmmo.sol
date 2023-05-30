// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {EnumerableSet} from "@oz/utils/structs/EnumerableSet.sol";
import {IBeepBoop} from "../interfaces/IBeepBoop.sol";

contract BeepBoopAmmo is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice Token Ids
    uint256 gameMintPrice = 50000e18;

    /// @notice Round => Tokens
    mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet))
        private _tokensWithAmmoForRound;

    /// @notice Season
    uint256 private _currentSeason;

    constructor(address beepBoop_) {
        beepBoop = IBeepBoop(beepBoop_);
    }

    /**
     * @notice Purchase a battery (limited using in-game)
     */
    function purchaseAmmo(uint256 round, uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0);
        uint256 season = _currentSeason;
        uint256 cost = tokenIds.length * gameMintPrice;
        IBeepBoop(beepBoop).spendBeepBoop(msg.sender, cost);
        for (uint256 t; t < tokenIds.length; ++t) {
            _tokensWithAmmoForRound[season][round].add(tokenIds[t]);
        }
    }

    /**
     * @notice Return the token ids with ammo
     */
    function getTokensWithAmmo(
        uint256 roundFrom,
        uint256 roundTo
    ) public view returns (uint256[] memory) {
        require(roundFrom <= roundTo);
        uint256 season = _currentSeason;
        uint256 tokenLength;
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            tokenLength += _tokensWithAmmoForRound[season][r].length();
        }
        uint256 tokenIdx;
        uint256[] memory tokenIds = new uint256[](tokenLength);
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            for (
                uint256 t;
                t < _tokensWithAmmoForRound[season][r].length();
                ++t
            ) {
                tokenIds[tokenIdx++] = _tokensWithAmmoForRound[season][r].at(t);
            }
        }
        return tokenIds;
    }

    /**
     * @notice Change the boop contract
     */
    function changeBeepBoopContract(address contract_) public onlyOwner {
        beepBoop = IBeepBoop(contract_);
    }

    /**
     * @notice Modify price
     */
    function setGameMintPrice(uint256 price) public onlyOwner {
        gameMintPrice = price;
    }

    /**
     * @notice Modify season
     */
    function setSeason(uint256 season) public onlyOwner {
        _currentSeason = season;
    }
}