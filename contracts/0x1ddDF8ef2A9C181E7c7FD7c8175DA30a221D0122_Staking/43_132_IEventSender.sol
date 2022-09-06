// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";

interface IEventSender {
    event DestinationsSet(address fxStateSender, address destinationOnL2);
    event EventSendSet(bool eventSendSet);

    /// @notice Configure the Polygon state sender root and destination for messages sent
    /// @param fxStateSender Address of Polygon State Sender Root contract
    /// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
    function setDestinations(address fxStateSender, address destinationOnL2) external;

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external;
}