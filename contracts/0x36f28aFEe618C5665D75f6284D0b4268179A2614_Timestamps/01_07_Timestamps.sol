// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Job Timestamps v1.0 
 *
 *  Timestamps are updated when:
 *      + salaries are claimed
 *      + regs transferred or unassigned
 *      + jobs transferred or unassigned
 */

// 4,294,967,295 Max uint32
// 1,659,412,538 Current timestamp
// 2,635,554,757 Difference = 83.52 years

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Timestamps is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint32[10001] private timestamps; 

    constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);
	}

    function get(uint _jobId) public view returns (uint) { 
        return timestamps[_jobId];
    }

    function getMany(uint[] memory _jobIds) public view returns (uint[] memory) { 
        uint[] memory _results = new uint[](_jobIds.length);
        for (uint i = 0;i < _jobIds.length; i++){
            _results[i] = timestamps[_jobIds[i]];
        }
        return _results;
    }

// Admin

    function set(uint _jobId, uint32 _timestamp) public onlyRole(MINTER_ROLE) {
        timestamps[_jobId] = _timestamp;
    }

    function setMany(uint[] memory _jobIds, uint32 _timestamp) public onlyRole(MINTER_ROLE) {
        for (uint i = 0;i < _jobIds.length; i++){
            timestamps[_jobIds[i]] = _timestamp;
        }
    }

}