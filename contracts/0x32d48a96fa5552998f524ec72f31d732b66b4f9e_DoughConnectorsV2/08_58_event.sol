// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ListInterface {
    function accountID(address) external view returns (uint64);
}


contract DoughEvent {

    address public immutable doughList;

    constructor (address _doughList) public {
        doughList = _doughList;
    }

    event LogEvent(uint64 connectorType, uint64 indexed connectorID, uint64 indexed accountID, bytes32 indexed eventCode, bytes eventData);

    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external {
        uint64 _ID = ListInterface(doughList).accountID(msg.sender);
        require(_ID != 0, "not-SA");
        emit LogEvent(uint64(_connectorType), uint64(_connectorID), _ID, _eventCode, _eventData);
    }

}