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

import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

import './Arrays.sol';
import './PermissionsManager.sol';
import { Permission, PermissionChange, PermissionChangeRequest } from './PermissionsData.sol';

library PermissionsHelpers {
    /**
     * @dev Builds a permission object
     * @param who Address to be referred
     * @param what Function selector to be referred
     */
    function permission(address who, bytes4 what) internal pure returns (Permission memory) {
        return Permission(what, who);
    }

    /**
     * @dev Builds a permission change object
     * @param grant Whether the permission should be granted or revoked
     * @param who Address to be referred
     * @param what Function selector to be referred
     */
    function change(bool grant, address who, bytes4 what) internal pure returns (PermissionChange memory) {
        return PermissionChange(grant, permission(who, what));
    }

    /**
     * @dev Grants permission to `who` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param who Address of the account that will be authorized
     * @param what Function selector to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address who, bytes4 what) internal {
        authorize(self, where, Arrays.from(who), Arrays.from(what));
    }

    /**
     * @dev Revokes permission from `who` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param who Address of the account that will be unauthorized
     * @param what Function selector to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address who, bytes4 what) internal {
        unauthorize(self, where, Arrays.from(who), Arrays.from(what));
    }

    /**
     * @dev Grants permission to `whos` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param whos List of addresses of the accounts that will be authorized
     * @param what Function selector to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4 what) internal {
        authorize(self, where, whos, Arrays.from(what));
    }

    /**
     * @dev Revokes permission from `whos` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param whos List of addresses of the accounts that will be unauthorized
     * @param what Function selector to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4 what) internal {
        unauthorize(self, where, whos, Arrays.from(what));
    }

    /**
     * @dev Grants permissions to `who` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param who Address of the account that will be authorized
     * @param whats List of function selectors to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address who, bytes4[] memory whats) internal {
        authorize(self, where, Arrays.from(who), whats);
    }

    /**
     * @dev Revokes permissions from `who` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param who Address of the account that will be unauthorized
     * @param whats List of function selectors to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address who, bytes4[] memory whats) internal {
        unauthorize(self, where, Arrays.from(who), whats);
    }

    /**
     * @dev Grants permissions to `whos` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param whos List of addresses of the accounts that will be authorized
     * @param whats List of function selectors to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4[] memory whats)
        internal
    {
        execute(self, where, whos, whats, true);
    }

    /**
     * @dev Revokes permissions from `whos` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param whos List of addresses of the accounts that will be unauthorized
     * @param whats List of function selectors to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4[] memory whats)
        internal
    {
        execute(self, where, whos, whats, false);
    }

    /**
     * @dev Executes a list of permission changes
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission change will be executed
     * @param whos List of addresses of the accounts that will be affected
     * @param whats List of function selectors to be affected
     * @param grant Whether the permissions should be granted or revoked
     */
    function execute(
        PermissionsManager self,
        IAuthorizer where,
        address[] memory whos,
        bytes4[] memory whats,
        bool grant
    ) private {
        PermissionChangeRequest[] memory requests = new PermissionChangeRequest[](1);
        requests[0].target = where;
        requests[0].changes = new PermissionChange[](whos.length * whats.length);

        for (uint256 i = 0; i < whos.length; i++) {
            for (uint256 j = 0; j < whats.length; j++) {
                uint256 index = (i * whats.length) + j;
                requests[0].changes[index] = change(grant, whos[i], whats[j]);
            }
        }

        self.execute(requests);
    }
}