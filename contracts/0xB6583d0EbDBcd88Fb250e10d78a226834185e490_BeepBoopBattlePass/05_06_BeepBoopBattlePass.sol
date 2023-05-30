// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {EnumerableSet} from "@oz/utils/structs/EnumerableSet.sol";
import {IBeepBoop} from "../interfaces/IBeepBoop.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

contract BeepBoopBattlePass is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice $BeepBoop
    IBeepBoop public beepBoop;

    /// @notice Token recipient
    address public tokenRecipient;

    /// @notice Token Ids
    uint256 price = 1000e18;

    /// @notice Round => Tokens
    mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet))
        private _tokensWithPassForRound;

    /// @notice Season
    uint256 private _currentSeason;

    /// @notice Limit of passes
    uint256 battlePassLimit = 5000;
    uint256 mintedBattlePasses;

    constructor(address beepBoop_, address tokenRecipient_) {
        beepBoop = IBeepBoop(beepBoop_);
        tokenRecipient = tokenRecipient_;
    }

    /**
     * @notice Purchase a battery (limited using in-game)
     */
    function purchase(uint256 round, uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0);
        require(
            mintedBattlePasses + tokenIds.length <= battlePassLimit,
            "No longer available"
        );
        uint256 cost = tokenIds.length * price;
        IERC20(address(beepBoop)).transferFrom(
            msg.sender,
            tokenRecipient,
            cost
        );
        mintedBattlePasses += tokenIds.length;
        uint256 season = _currentSeason;
        for (uint256 t; t < tokenIds.length; ++t) {
            _tokensWithPassForRound[season][round].add(tokenIds[t]);
        }
    }

    /**
     * @notice Return the token ids with battle pass
     */
    function getTokensWithPass(
        uint256 roundFrom,
        uint256 roundTo
    ) public view returns (uint256[] memory) {
        require(roundFrom <= roundTo);
        uint256 tokenLength;
        uint256 season = _currentSeason;
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            tokenLength += _tokensWithPassForRound[season][r].length();
        }
        uint256 tokenIdx;
        uint256[] memory tokenIds = new uint256[](tokenLength);
        for (uint256 r = roundFrom; r <= roundTo; r++) {
            for (
                uint256 t;
                t < _tokensWithPassForRound[season][r].length();
                ++t
            ) {
                tokenIds[tokenIdx++] = _tokensWithPassForRound[season][r].at(t);
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
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    /**
     * @notice Set token recipient
     */
    function setTokenRecipient(address address_) public onlyOwner {
        tokenRecipient = address_;
    }

    /**
     * @notice Set battle pass limit
     */
    function setBattlePassLimit(uint256 limit_) public onlyOwner {
        battlePassLimit = limit_;
    }

    /**
     * @notice Modify season
     */
    function setSeason(uint256 season) public onlyOwner {
        _currentSeason = season;
    }
}