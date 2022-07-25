// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Seniority v1.0 
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Seniority is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public MAX_LEVELS = 5;
    mapping(uint => uint) private levels;

    event LevelUpdate (uint _tokenId, uint _newLevel);

    constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, tx.origin);
	}

    function level(uint _jobID) public view returns (uint) {
        // jobs start with level 0 or 1, based on a cointoss;
        return levels[_jobID] + cointoss(_jobID);
    }

    // Admin

    function incrementLevel(uint _jobID) public onlyRole(MINTER_ROLE) {
        require(level(_jobID) < MAX_LEVELS, "At max level");
        levels[_jobID] += 1;
        emit LevelUpdate(_jobID, level(_jobID));
    }

    function setLevel(uint _jobID, uint _newLevel) public onlyRole(MINTER_ROLE) {
        require(_newLevel <= MAX_LEVELS, "Level too high");
        levels[_jobID] = _newLevel;
        emit LevelUpdate(_jobID, level(_jobID));
    }

    function setMaxLevels(uint _newMax) public onlyRole(MINTER_ROLE) {
        MAX_LEVELS = _newMax;
    }

    // Internal

    function cointoss(uint _num) internal pure returns (uint){
        return (uint(keccak256(abi.encodePacked(_num))) % 2);
    }

}