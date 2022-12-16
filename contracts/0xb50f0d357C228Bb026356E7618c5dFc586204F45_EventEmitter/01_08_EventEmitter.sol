// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EventEmitter is AccessControl {
    event Event(string eventName, bytes eventData);
    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PROXY_ROLE, msg.sender);
    }

    function emitEvent(string memory eventName, bytes calldata eventData)
        public
        onlyRole(PROXY_ROLE)
        returns (bool)
    {
        emit Event(eventName, eventData);
        return true;
    }
}