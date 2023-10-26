// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title The CflatsDatabase contract is the implementation of a transparent 
/// database for the CryptoFlats project. The contract has basic properties for databases, 
/// namely storage and deletion of information, in this case information about users of the CryptoFlats project is stored
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../errors/CflatsDatabaseErrors.sol";
import "./ICflatsDatabase.sol";


contract CflatsDatabase is ICflatsDatabase, AccessControl
{
    bytes32 public constant BLACKLISTED_ROLE =  0x000000000000000000000000000000000000000000000000000000000000dead;
    bytes32 public constant OPERATOR_ROLE =     0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant DEVELOPER_ROLE =    0x0000000000000000000000000000000000000000000000000000000000000002;
    bytes32 public constant USER_ROLE =         0x0000000000000000000000000000000000000000000000000000000000000003;

    address public immutable TEAM_WALLET;

    uint256 private _usersCount;

    mapping(address account => User user) private _users;
    mapping(address user => bool exists) private _userExists;

    constructor(address teamWallet)
    {
        _usersCount = 0;
        TEAM_WALLET = teamWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isBlacklisted(address user) public view returns (bool)
    {
        return hasRole(BLACKLISTED_ROLE, user);
    }


    function userExists(address user) public view returns (bool)
    {
        return _userExists[user] != false;
    }



    function getUserByAccountAddress(address user) public view returns (User memory)
    {
        return _users[user];
    }


    function getUsersCount() public view returns (uint256)
    {
        return _usersCount;
    }



    function addUser(address user) 
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        if(userExists(user) != false)
        {
            return false;
        }

        _addUser(user);
        return true;
    }


    function addUsersBatch(address[] calldata users) 
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 usersLength = users.length;
        for(uint256 i = 0; i < usersLength;)
        {
            address _user = users[i];

            if(_user == address(0))
            {
                revert ZeroAddress();
            }

            _addUser(_user);

            unchecked { ++i; }
        }

        return true;
    }


    function removeUser(address user) 
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        _removeUser(user);
        return true;
    }


    function removeUsersBatch(address[] memory users)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        uint256 usersToDeleteLength = users.length;

        if(usersToDeleteLength > getUsersCount())
        {
            revert UsersToDeleteExceedAmountOfDatabaseInsertedUsers();
        }

        for(uint256 i = 0; i < usersToDeleteLength;)
        {
            _removeUser(users[i]);
            unchecked { ++i; }
        }

        return true;
    }


    function addUserInBlacklist(address user) 
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        if(isBlacklisted(user) != false)
        {
            return false;
        }

        _grantRole(BLACKLISTED_ROLE, user);
        emit UserBlacklisted(user);

        return true;
    }

    function removeUserFromBlacklist(address user) 
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {

        if(isBlacklisted(user) != true)
        {
            return false;
        }

        _grantRole(USER_ROLE, user);
        emit UserRemovedFromBlacklist(user);

        return true;
    }




    function renounceRole(bytes32, address account) public override
    {
        if(isBlacklisted(account))
        {
            revert BlacklistedError();
        }

        User storage user = _users[account];
        super.renounceRole(user._role, account);
        user._role = USER_ROLE;
    }


    function _grantRole(bytes32 role, address account) internal override 
    {
        _changeRole(role, account);
    }


    function _revokeRole(bytes32, address account) internal override
    {
        User storage user = _users[account];
        super._revokeRole(user._role, account);
        user._role = USER_ROLE;
    }


    function _changeRole(bytes32 newRole, address account) private 
    {
        User storage user = _users[account];
        
        if(hasRole(user._role, account) != false)
        {
            super._revokeRole(user._role, account);
        }

        user._role = newRole;
        super._grantRole(newRole, account);
    }


    function _addUser(address user) private 
    {
        // required not to be zero address
        if(user == address(0))
        {
            revert ZeroAddress();
        }
        if(userExists(user) != false)
        {
            return;
        }


        _userExists[user] = true;
        _users[user]._account = user;


        // Setting a role to user
        // If the user has already been granted a role
        // before saving it in the database, then we save
        // this role in a table cell, otherwise default user role
        _grantRole(_getUserRole(user), user);


        unchecked { ++_usersCount; }
        emit UserInserted(user);
    }


    function _removeUser(address user) private
    {
        _requireUserExist(user);

        // deleting data about the user
        _revokeRole(0x00, user);
        delete _users[user];
        delete _userExists[user];

        unchecked { --_usersCount; }
        emit UserRemoved(user);
    }



    function _getUserRole(address user) private view returns(bytes32)
    {
        if(hasRole(DEFAULT_ADMIN_ROLE, user) == true)
        {
            return DEFAULT_ADMIN_ROLE;
        }
        else if(hasRole(BLACKLISTED_ROLE, user) == true)
        {
            return BLACKLISTED_ROLE;
        }
        else if(hasRole(OPERATOR_ROLE, user) == true)
        {
            return OPERATOR_ROLE;
        }
        else if(hasRole(DEVELOPER_ROLE, user) == true)
        {
            return DEVELOPER_ROLE;
        }

        return USER_ROLE;
    }


    function _requireUserExist(address user) private view
    {
        if(userExists(user) != true)
        {
            revert UserDoesNotExistsError(user);
        }
    }
}