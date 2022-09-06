// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MetadataStorage is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant MAX_ID = 9999;

    uint128[10000] private traits;

    event Set (uint id);
    event SetMany (uint start, uint length);

    constructor() { 
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);
    }

    function setMany(uint[] memory _ids, uint128[] memory _traits) public onlyRole(MINTER_ROLE) {
        require(_ids.length == _traits.length, "mismatch");
        for (uint i; i < _ids.length; i++) {
            traits[_ids[i]] = _traits[i];
        }
        emit SetMany(_ids[0],_ids.length);
    }

    function set(uint _id, uint128 _trait) public onlyRole(MINTER_ROLE) {
        require(_id <= MAX_ID, "Id exceeds max");
        traits[_id] = _trait;
        emit Set(_id);
    }

    function get(uint _id) public view returns (uint) {
        require(_id <= MAX_ID, "Id exceeds max");
        return traits[_id];
    }

}