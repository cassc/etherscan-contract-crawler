// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import {ISTokenManagerStruct} from "./ISTokenManagerStruct.sol";

interface ISTokenManagerDescriptor {
	/*
	 * @dev get toke uri from position information.
	 * @param _property The struct of positon information
	 * @param _amount The struct of positon information
	 * @param _cumulativeReward Cumulative Rewards
	 * @param _tokeUriImage The struct of positon information
	 */
	function getTokenURI(
		address _property,
		uint256 _amount,
		uint256 _cumulativeReward,
		string memory _tokeUriImage
	) external pure returns (string memory);
}