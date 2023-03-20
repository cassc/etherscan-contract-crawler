// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import {SingleRanking} from "src/lib/SingleRanking.sol";
import {IRebornPortal} from "src/interfaces/IRebornPortal.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

library DegenRank {
    using SingleRanking for SingleRanking.Data;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    function _enterScoreRank(
        IRebornPortal.SeasonData storage _seasonData,
        uint256 tokenId,
        uint256 value
    ) external {
        if (value == 0) {
            return;
        }
        // only when length is larger than 100, remove
        if (SingleRanking.length(_seasonData._scoreRank) >= 100) {
            // get the min value and compare, if new value is not larger, nothing happen
            if (value <= _seasonData._minScore) {
                return;
            }
            // remove the smallest in the score rank
            uint256 tokenIdWithMinmalScore = _seasonData._scoreRank.get(99, 1)[
                0
            ];
            _seasonData._scoreRank.remove(
                tokenIdWithMinmalScore,
                _seasonData._minScore
            );

            // also remove it from tvl rank
            _seasonData._isTopHundredScore.unset(tokenIdWithMinmalScore);
            _exitTvlRank(
                _seasonData._tributeRank,
                _seasonData._oldStakeAmounts,
                tokenIdWithMinmalScore
            );

            // set min value
            _seasonData._minScore = _seasonData._scoreRank.getNthValue(99);
        }

        // add to score rank
        _seasonData._scoreRank.add(tokenId, value);
        // can enter the tvl rank
        _seasonData._isTopHundredScore.set(tokenId);

        // Enter as a very small value, just ensure it's not zero and pass check
        // it doesn't matter too much as really stake has decimal with 18.
        // General value woule be much larger than 1
        _enterTvlRank(
            _seasonData._tributeRank,
            _seasonData._isTopHundredScore,
            _seasonData._oldStakeAmounts,
            tokenId,
            1
        );
    }

    /**
     * @dev set a new value in tree, only save top x largest value
     * @param value new value enters in the tree
     */
    function _enterTvlRank(
        SingleRanking.Data storage _tributeRank,
        BitMapsUpgradeable.BitMap storage _isTopHundredScore,
        mapping(uint256 => uint256) storage _oldStakeAmounts,
        uint256 tokenId,
        uint256 value
    ) public {
        // if it's not one hundred score, nothing happens
        if (!_isTopHundredScore.get(tokenId)) {
            return;
        }

        // remove old value from the rank, keep one token Id only one value
        if (_oldStakeAmounts[tokenId] != 0) {
            _tributeRank.remove(tokenId, _oldStakeAmounts[tokenId]);
        }
        _tributeRank.add(tokenId, value);
        _oldStakeAmounts[tokenId] = value;
    }

    /**
     * @dev if the tokenId's value is zero, it exits the ranking
     * @dev reduce rank size and release some gas
     * @param tokenId pool tokenId
     */
    function _exitTvlRank(
        SingleRanking.Data storage _tributeRank,
        mapping(uint256 => uint256) storage _oldStakeAmounts,
        uint256 tokenId
    ) internal {
        if (_oldStakeAmounts[tokenId] != 0) {
            _tributeRank.remove(tokenId, _oldStakeAmounts[tokenId]);
            delete _oldStakeAmounts[tokenId];
        }
    }

    /**
     * @dev exit from score rank and tvl rank, used when anti Cheat
     * @param _seasonData season data storage
     * @param tokenId tokenId
     * @param oldValue old value
     */
    function _exitRank(
        IRebornPortal.SeasonData storage _seasonData,
        uint256 tokenId,
        uint256 oldValue
    ) internal {
        // if it's not top 100 hundred, do nothing
        if (!_seasonData._isTopHundredScore.get(tokenId)) {
            return;
        }
        // remove from score rank
        _seasonData._scoreRank.remove(tokenId, oldValue);

        // also remove it from top hundred score
        _seasonData._isTopHundredScore.unset(tokenId);

        // also remove it from tvl rank
        _exitTvlRank(
            _seasonData._tributeRank,
            _seasonData._oldStakeAmounts,
            tokenId
        );
    }
}