// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";
import "./IEventSender.sol";

/// @title Base contract for sending events to our Governance layer
abstract contract EventSender is IEventSender {
	bool public eventSend;
	Destinations public destinations;

	modifier onEventSend() {
		// Only send the event when enabled
		if (eventSend) {
			_;
		}
	}

	modifier onlyEventSendControl() {
		// Give the implementing contract control over permissioning
		require(canControlEventSend(), "CANNOT_CONTROL_EVENTS");
		_;
	}

	/// @notice Configure the Polygon state sender root and destination for messages sent
	/// @param fxStateSender Address of Polygon State Sender Root contract
	/// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
	function setDestinations(
		address fxStateSender,
		address destinationOnL2
	) external virtual override onlyEventSendControl {
		require(fxStateSender != address(0), "INVALID_FX_ADDRESS");
		require(destinationOnL2 != address(0), "INVALID_DESTINATION_ADDRESS");

		destinations.fxStateSender = IFxStateSender(fxStateSender);
		destinations.destinationOnL2 = destinationOnL2;

		emit DestinationsSet(fxStateSender, destinationOnL2);
	}

	/// @notice Enables or disables the sending of events
	function setEventSend(bool eventSendSet) external virtual override onlyEventSendControl {
		eventSend = eventSendSet;

		emit EventSendSet(eventSendSet);
	}

	/// @notice Determine permissions for controlling event sending
	/// @dev Should not revert, just return false
	function canControlEventSend() internal view virtual returns (bool);

	/// @notice Send event data to Governance layer
	function sendEvent(bytes memory data) internal virtual {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}
}