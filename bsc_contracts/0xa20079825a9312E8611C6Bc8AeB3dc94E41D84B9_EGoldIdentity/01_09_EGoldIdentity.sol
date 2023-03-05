//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../library/EGoldUtils.sol";

contract EGoldIdentity is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    mapping(address => EGoldUtils.userData) private Users;

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setUser( address _parent ,  EGoldUtils.userData memory userData) external onlyRole(TREASURY_ROLE) {
        Users[_parent] = userData;
    }

    function updateUser( address _parent ,  EGoldUtils.userData memory userData) external onlyRole(TREASURY_ROLE) {
        Users[_parent] = userData;
    }

    function fetchUser( address _parent ) external view onlyRole(TREASURY_ROLE) returns ( EGoldUtils.userData memory ) {
        return Users[_parent];
    }

}