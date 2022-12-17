//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title the interface for the sport event
interface IMetabetMask {
    
    /// @notice The possible outcome for an event
    enum EventOutcome {
        Pending,    // match has not been fought to decision
        Decided   // match has been finally Decided 
    }

    /***
    * @dev defines a sport event along with its outcome
    */
    struct SportEvent {
        bytes32       id;
        string        teamA; 
        string        teamB;
        int8        result; //0 for teamA 1 for teamB.
        uint          startTimestamp; 
        address     bnbPool;
        address     goalPool;
        address     busdPool;
        EventOutcome  outcome;
    }
    

    // check if event exists
    function eventExists(bytes32 _eventId)
        external view returns (bool);
    
    // get all pending events
    function getPendingEvents() 
        external view returns (SportEvent[] memory);

    // get events using eventids
    function getEvents(bytes32[] memory eventIds) 
        external view returns (SportEvent[] memory);

    // get Live events
    function getLiveEvents()
        external view returns (SportEvent[] memory);

    // get events using indexes
    function getIndexedEvents(uint[] memory indexes) 
        external view returns (SportEvent[] memory);

    function getEventsLength()
        external view returns(uint);

}