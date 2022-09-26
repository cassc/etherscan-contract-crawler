// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ITroveManagerHelpers.sol";
import "./SortedTroves.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core Dfranc system. */
contract MultiTroveGetter {
	struct CombinedTroveData {
		address owner;
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		uint256 snapshotAsset;
		uint256 snapshotDCHFDebt;
	}

	ITroveManager public troveManager; // XXX Troves missing from ITroveManager?
	ITroveManagerHelpers public troveManagerHelpers;
	ISortedTroves public sortedTroves;

	constructor(
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers,
		ISortedTroves _sortedTroves
	) {
		troveManager = _troveManager;
		troveManagerHelpers = _troveManagerHelpers;
		sortedTroves = _sortedTroves;
	}

	function getMultipleSortedTroves(
		address _asset,
		int256 _startIdx,
		uint256 _count
	) external view returns (CombinedTroveData[] memory _troves) {
		uint256 startIdx;
		bool descend;

		if (_startIdx >= 0) {
			startIdx = uint256(_startIdx);
			descend = true;
		} else {
			startIdx = uint256(-(_startIdx + 1));
			descend = false;
		}

		uint256 sortedTrovesSize = sortedTroves.getSize(_asset);

		if (startIdx >= sortedTrovesSize) {
			_troves = new CombinedTroveData[](0);
		} else {
			uint256 maxCount = sortedTrovesSize - startIdx;

			if (_count > maxCount) {
				_count = maxCount;
			}

			if (descend) {
				_troves = _getMultipleSortedTrovesFromHead(_asset, startIdx, _count);
			} else {
				_troves = _getMultipleSortedTrovesFromTail(_asset, startIdx, _count);
			}
		}
	}

	function _getMultipleSortedTrovesFromHead(
		address _asset,
		uint256 _startIdx,
		uint256 _count
	) internal view returns (CombinedTroveData[] memory _troves) {
		address currentTroveowner = sortedTroves.getFirst(_asset);

		for (uint256 idx = 0; idx < _startIdx; ++idx) {
			currentTroveowner = sortedTroves.getNext(_asset, currentTroveowner);
		}

		_troves = new CombinedTroveData[](_count);

		for (uint256 idx = 0; idx < _count; ++idx) {
			_troves[idx].owner = currentTroveowner;
			(
				_troves[idx].asset,
				_troves[idx].debt,
				_troves[idx].coll,
				_troves[idx].stake,
				/* status */
				/* arrayIndex */
				,

			) = troveManagerHelpers.getTrove(_asset, currentTroveowner);
			(_troves[idx].snapshotAsset, _troves[idx].snapshotDCHFDebt) = troveManagerHelpers
				.getRewardSnapshots(_asset, currentTroveowner);

			currentTroveowner = sortedTroves.getNext(_asset, currentTroveowner);
		}
	}

	function _getMultipleSortedTrovesFromTail(
		address _asset,
		uint256 _startIdx,
		uint256 _count
	) internal view returns (CombinedTroveData[] memory _troves) {
		address currentTroveowner = sortedTroves.getLast(_asset);

		for (uint256 idx = 0; idx < _startIdx; ++idx) {
			currentTroveowner = sortedTroves.getPrev(_asset, currentTroveowner);
		}

		_troves = new CombinedTroveData[](_count);

		for (uint256 idx = 0; idx < _count; ++idx) {
			_troves[idx].owner = currentTroveowner;
			(
				_troves[idx].asset,
				_troves[idx].debt,
				_troves[idx].coll,
				_troves[idx].stake,
				/* status */
				/* arrayIndex */
				,

			) = troveManagerHelpers.getTrove(_asset, currentTroveowner);
			(_troves[idx].snapshotAsset, _troves[idx].snapshotDCHFDebt) = troveManagerHelpers
				.getRewardSnapshots(_asset, currentTroveowner);

			currentTroveowner = sortedTroves.getPrev(_asset, currentTroveowner);
		}
	}
}