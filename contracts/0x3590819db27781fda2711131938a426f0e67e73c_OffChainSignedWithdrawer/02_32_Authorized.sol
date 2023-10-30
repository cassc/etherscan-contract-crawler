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

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './AuthorizedHelpers.sol';
import './interfaces/IAuthorized.sol';
import './interfaces/IAuthorizer.sol';

/**
 * @title Authorized
 * @dev Implementation using an authorizer as its access-control mechanism. It offers `auth` and `authP` modifiers to
 * tag its own functions in order to control who can access them against the authorizer referenced.
 */
contract Authorized is IAuthorized, Initializable, AuthorizedHelpers {
    // Authorizer reference
    address public override authorizer;

    /**
     * @dev Modifier that should be used to tag protected functions
     */
    modifier auth() {
        _authenticate(msg.sender, msg.sig);
        _;
    }

    /**
     * @dev Modifier that should be used to tag protected functions with params
     */
    modifier authP(uint256[] memory params) {
        _authenticate(msg.sender, msg.sig, params);
        _;
    }

    /**
     * @dev Creates a new authorized contract. Note that initializers are disabled at creation time.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the authorized contract. It does call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     */
    function __Authorized_init(address _authorizer) internal onlyInitializing {
        __Authorized_init_unchained(_authorizer);
    }

    /**
     * @dev Initializes the authorized contract. It does not call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     */
    function __Authorized_init_unchained(address _authorizer) internal onlyInitializing {
        authorizer = _authorizer;
    }

    /**
     * @dev Reverts if `who` is not allowed to call `what`
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     */
    function _authenticate(address who, bytes4 what) internal view {
        _authenticate(who, what, new uint256[](0));
    }

    /**
     * @dev Reverts if `who` is not allowed to call `what` with `how`
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     * @param how Params to be authenticated
     */
    function _authenticate(address who, bytes4 what, uint256[] memory how) internal view {
        if (!_isAuthorized(who, what, how)) revert AuthSenderNotAllowed(who, what, how);
    }

    /**
     * @dev Tells whether `who` has any permission on this contract
     * @param who Address asking permissions for
     */
    function _hasPermissions(address who) internal view returns (bool) {
        return IAuthorizer(authorizer).hasPermissions(who, address(this));
    }

    /**
     * @dev Tells whether `who` is allowed to call `what`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function _isAuthorized(address who, bytes4 what) internal view returns (bool) {
        return _isAuthorized(who, what, new uint256[](0));
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` with `how`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function _isAuthorized(address who, bytes4 what, uint256[] memory how) internal view returns (bool) {
        return IAuthorizer(authorizer).isAuthorized(who, address(this), what, how);
    }
}