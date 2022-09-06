//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MorpherAccessControl.sol";
import "./MorpherState.sol";


contract MorpherUserBlocking is Initializable {

    mapping(address => bool) public userIsBlocked;
    MorpherState state;

    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 public constant USERBLOCKINGADMIN_ROLE = keccak256("USERBLOCKINGADMIN_ROLE");

    event ChangeUserBlocked(address _user, bool _oldIsBlocked, bool _newIsBlocked);
    event ChangedAddressAllowedToAddBlockedUsersAddress(address _oldAddress, address _newAddress);

    function initialize(address _state) public initializer {
        state = MorpherState(_state);
    }

    modifier onlyAdministrator() {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, msg.sender), "UserBlocking: Only Administrator can call this function");
        _;
    }

    modifier onlyAllowedUsers() {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, msg.sender) || MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(USERBLOCKINGADMIN_ROLE, msg.sender), "UserBlocking: Only White-Listed Users can call this function");
        _;
    }

    function setUserBlocked(address _user, bool _isBlocked) public onlyAllowedUsers {
        emit ChangeUserBlocked(_user, userIsBlocked[_user], _isBlocked);
        userIsBlocked[_user] = _isBlocked;
    }
}