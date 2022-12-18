// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solady/src/utils/SafeTransferLib.sol";

contract AlarmClock {

	event FufillmentScheduled(uint128 creationId, uint128 fufillmentId, uint256 reward);

    uint128 internal _nextFufillmentId;

	mapping(bytes32 => bool) internal _fufillments;

    function currentFufillmentReward() public view returns (uint256) {
        return 60000 * block.basefee;
    }

	function create(uint128 creationId) public payable {
		uint256 reward = currentFufillmentReward();
		
        uint128 fufillmentId = _nextFufillmentId;

		bytes32 fufillmentHash = keccak256(abi.encode(
			creationId,
            fufillmentId,
			reward
		));
		
		require(msg.value >= reward);

		_fufillments[fufillmentHash] = true;
        _nextFufillmentId += 1;

		emit FufillmentScheduled(creationId, fufillmentId, reward);
	}

	function fufill(uint128 creationId, uint128 fufillmentId, uint256 reward) public payable {
		bytes32 fufillmentHash = keccak256(abi.encode(
			creationId,
            fufillmentId,
			reward
		));

		require(_fufillments[fufillmentHash]);

		delete _fufillments[fufillmentHash];

        SafeTransferLib.forceSafeTransferETH(msg.sender, reward);
	}
}