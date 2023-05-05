// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import './IAuthorizer.sol';

/**
 * @title Authorizer
 * @dev Authorization module to be used by contracts that need to implement permissions for their methods.
 * It provides a permissions model to list who is allowed to call what function in a contract. And only accounts
 * authorized to manage those permissions are the ones that are allowed to authorize or unauthorize accounts.
 */
contract Authorizer is IAuthorizer {
    // Constant used to denote that a permission is open to anyone
    address public constant ANY_ADDRESS = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Internal mapping to tell who is allowed to do what indexed by (account, function selector)
    mapping (address => mapping (bytes4 => bool)) private authorized;

    /**
     * @dev Modifier that should be used to tag protected functions
     */
    modifier auth() {
        _authenticate(msg.sender, msg.sig);
        _;
    }

    /**
     * @dev Tells whether someone is allowed to call a function or not. It returns true if it's allowed to anyone.
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function isAuthorized(address who, bytes4 what) public view override returns (bool) {
        return authorized[ANY_ADDRESS][what] || authorized[who][what];
    }

    /**
     * @dev Authorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function authorize(address who, bytes4 what) external override auth {
        _authorize(who, what);
    }

    /**
     * @dev Unauthorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, bytes4 what) external override auth {
        _unauthorize(who, what);
    }

    /**
     * @dev Internal function to authenticate someone over a function.
     * It reverts if the given account is not authorized to call the requested function.
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     */
    function _authenticate(address who, bytes4 what) internal view {
        require(isAuthorized(who, what), 'AUTH_SENDER_NOT_ALLOWED');
    }

    /**
     * @dev Internal function to authorize someone to call a function
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function _authorize(address who, bytes4 what) internal {
        authorized[who][what] = true;
        emit Authorized(who, what);
    }

    /**
     * @dev Internal function to unauthorize someone to call a function
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function _unauthorize(address who, bytes4 what) internal {
        authorized[who][what] = false;
        emit Unauthorized(who, what);
    }
}