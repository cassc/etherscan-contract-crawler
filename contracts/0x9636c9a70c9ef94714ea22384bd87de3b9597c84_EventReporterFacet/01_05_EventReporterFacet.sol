//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/EventReporterLib.sol";

/// @title ERC721AAttributes
/// @notice the total balance of a token type
contract EventReporterFacet {

    /// @notice get a reference to the global event reporter contract
    function eventReporter() external view returns (address){
        return EventReporterLib.getEventReportingContract();
    }

}