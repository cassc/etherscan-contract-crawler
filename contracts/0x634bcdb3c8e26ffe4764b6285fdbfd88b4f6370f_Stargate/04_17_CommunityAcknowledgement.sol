// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Ownable.sol";

contract CommunityAcknowledgement is Ownable {

	/// @notice Recognised Community Contributor Acknowledgement Rate
	/// @dev Id is keccak256 hash of contributor address
	mapping (bytes32 => uint16) public rccar;

	/// @notice Emit when owner recognises contributor
	/// @param contributor Keccak256 hash of recognised contributor address
	/// @param previousAcknowledgementRate Previous contributor acknowledgement rate
	/// @param newAcknowledgementRate New contributor acknowledgement rate
	event ContributorRecognised(bytes32 indexed contributor, uint16 indexed previousAcknowledgementRate, uint16 indexed newAcknowledgementRate);

	/* solhint-disable-next-line no-empty-blocks */
	constructor(address _adoptionDAOAddress) Ownable(_adoptionDAOAddress) {

	}

	/// @notice Getter for Recognised Community Contributor Acknowledgement Rate
	/// @param _contributor Keccak256 hash of contributor address
	/// @return Acknowledgement Rate
	function getAcknowledgementRate(bytes32 _contributor) external view returns (uint16) {
		return rccar[_contributor];
	}

	/// @notice Getter for Recognised Community Contributor Acknowledgement Rate for msg.sender
	/// @return Acknowledgement Rate
	function senderAcknowledgementRate() external view returns (uint16) {
		return rccar[keccak256(abi.encodePacked(msg.sender))];
	}

	/// @notice Recognise community contributor and set its acknowledgement rate
	/// @dev Only owner can recognise contributor
	/// @dev Emits `ContributorRecognised` event
	/// @param _contributor Keccak256 hash of recognised contributor address
	/// @param _acknowledgementRate Contributor new acknowledgement rate
	function recogniseContributor(bytes32 _contributor, uint16 _acknowledgementRate) public onlyOwner {
		uint16 _previousAcknowledgementRate = rccar[_contributor];
		rccar[_contributor] = _acknowledgementRate;
		emit ContributorRecognised(_contributor, _previousAcknowledgementRate, _acknowledgementRate);
	}

	/// @notice Recognise list of contributors
	/// @dev Only owner can recognise contributors
	/// @dev Emits `ContributorRecognised` event for every contributor
	/// @param _contributors List of keccak256 hash of recognised contributor addresses
	/// @param _acknowledgementRates List of contributors new acknowledgement rates
	function batchRecogniseContributor(bytes32[] calldata _contributors, uint16[] calldata _acknowledgementRates) external onlyOwner {
		require(_contributors.length == _acknowledgementRates.length, "Lists do not match in length");

		for (uint256 i = 0; i < _contributors.length; i++) {
			recogniseContributor(_contributors[i], _acknowledgementRates[i]);
		}
	}

}