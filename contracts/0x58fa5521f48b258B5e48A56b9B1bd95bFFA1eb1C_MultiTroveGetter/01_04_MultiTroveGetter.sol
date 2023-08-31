// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "ITroveManager.sol";
import "ISortedTroves.sol";
import "IFactory.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core Prisma system. */
contract MultiTroveGetter {
    struct CombinedTroveData {
        address owner;
        uint256 debt;
        uint256 coll;
        uint256 stake;
        uint256 snapshotCollateral;
        uint256 snapshotDebt;
    }

    constructor() {}

    function getMultipleSortedTroves(
        ITroveManager troveManager,
        int _startIdx,
        uint256 _count
    ) external view returns (CombinedTroveData[] memory _troves) {
        ISortedTroves sortedTroves = ISortedTroves(troveManager.sortedTroves());
        uint256 startIdx;
        bool descend;

        if (_startIdx >= 0) {
            startIdx = uint256(_startIdx);
            descend = true;
        } else {
            startIdx = uint256(-(_startIdx + 1));
            descend = false;
        }

        uint256 sortedTrovesSize = sortedTroves.getSize();

        if (startIdx >= sortedTrovesSize) {
            _troves = new CombinedTroveData[](0);
        } else {
            uint256 maxCount = sortedTrovesSize - startIdx;

            if (_count > maxCount) {
                _count = maxCount;
            }

            if (descend) {
                _troves = _getMultipleSortedTrovesFromHead(troveManager, sortedTroves, startIdx, _count);
            } else {
                _troves = _getMultipleSortedTrovesFromTail(troveManager, sortedTroves, startIdx, _count);
            }
        }
    }

    function _getMultipleSortedTrovesFromHead(
        ITroveManager troveManager,
        ISortedTroves sortedTroves,
        uint256 _startIdx,
        uint256 _count
    ) internal view returns (CombinedTroveData[] memory _troves) {
        address currentTroveowner = sortedTroves.getFirst();

        for (uint256 idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }

        _troves = new CombinedTroveData[](_count);

        for (uint256 idx = 0; idx < _count; ++idx) {
            _troves[idx].owner = currentTroveowner;
            (
                _troves[idx].debt,
                _troves[idx].coll,
                _troves[idx].stake,
                /* status */
                /* arrayIndex */
                /* interestIndex */
                ,
                ,

            ) = troveManager.Troves(currentTroveowner);
            (_troves[idx].snapshotCollateral, _troves[idx].snapshotDebt) = troveManager.rewardSnapshots(
                currentTroveowner
            );

            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }
    }

    function _getMultipleSortedTrovesFromTail(
        ITroveManager troveManager,
        ISortedTroves sortedTroves,
        uint256 _startIdx,
        uint256 _count
    ) internal view returns (CombinedTroveData[] memory _troves) {
        address currentTroveowner = sortedTroves.getLast();

        for (uint256 idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getPrev(currentTroveowner);
        }

        _troves = new CombinedTroveData[](_count);

        for (uint256 idx = 0; idx < _count; ++idx) {
            _troves[idx].owner = currentTroveowner;
            (
                _troves[idx].debt,
                _troves[idx].coll,
                _troves[idx].stake,
                /* status */
                /* arrayIndex */
                /* interestIndex */
                ,
                ,

            ) = troveManager.Troves(currentTroveowner);
            (_troves[idx].snapshotCollateral, _troves[idx].snapshotDebt) = troveManager.rewardSnapshots(
                currentTroveowner
            );

            currentTroveowner = sortedTroves.getPrev(currentTroveowner);
        }
    }
}