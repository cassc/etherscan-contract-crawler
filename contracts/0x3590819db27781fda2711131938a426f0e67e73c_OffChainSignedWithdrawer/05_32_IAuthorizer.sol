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

pragma solidity >=0.8.0;

/**
 * @dev Authorizer interface
 */
interface IAuthorizer {
    /**
     * @dev Permission change
     * @param where Address of the contract to change a permission for
     * @param changes List of permission changes to be executed
     */
    struct PermissionChange {
        address where;
        GrantPermission[] grants;
        RevokePermission[] revokes;
    }

    /**
     * @dev Grant permission data
     * @param who Address to be authorized
     * @param what Function selector to be authorized
     * @param params List of params to restrict the given permission
     */
    struct GrantPermission {
        address who;
        bytes4 what;
        Param[] params;
    }

    /**
     * @dev Revoke permission data
     * @param who Address to be unauthorized
     * @param what Function selector to be unauthorized
     */
    struct RevokePermission {
        address who;
        bytes4 what;
    }

    /**
     * @dev Params used to validate permissions params against
     * @param op ID of the operation to compute in order to validate a permission param
     * @param value Comparison value
     */
    struct Param {
        uint8 op;
        uint248 value;
    }

    /**
     * @dev Sender is not authorized to call `what` on `where` with `how`
     */
    error AuthorizerSenderNotAllowed(address who, address where, bytes4 what, uint256[] how);

    /**
     * @dev The operation param is invalid
     */
    error AuthorizerInvalidParamOp(uint8 op);

    /**
     * @dev Emitted every time `who`'s permission to perform `what` on `where` is granted with `params`
     */
    event Authorized(address indexed who, address indexed where, bytes4 indexed what, Param[] params);

    /**
     * @dev Emitted every time `who`'s permission to perform `what` on `where` is revoked
     */
    event Unauthorized(address indexed who, address indexed where, bytes4 indexed what);

    /**
     * @dev Tells whether `who` has any permission on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function hasPermissions(address who, address where) external view returns (bool);

    /**
     * @dev Tells the number of permissions `who` has on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function getPermissionsLength(address who, address where) external view returns (uint256);

    /**
     * @dev Tells whether `who` has permission to call `what` on `where`. Note `how` is not evaluated here,
     * which means `who` might be authorized on or not depending on the call at the moment of the execution
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     */
    function hasPermission(address who, address where, bytes4 what) external view returns (bool);

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function isAuthorized(address who, address where, bytes4 what, uint256[] memory how) external view returns (bool);

    /**
     * @dev Tells the params set for a given permission
     * @param who Address asking permission params of
     * @param where Target address asking permission params of
     * @param what Function selector asking permission params of
     */
    function getPermissionParams(address who, address where, bytes4 what) external view returns (Param[] memory);

    /**
     * @dev Executes a list of permission changes
     * @param changes List of permission changes to be executed
     */
    function changePermissions(PermissionChange[] memory changes) external;

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function authorize(address who, address where, bytes4 what, Param[] memory params) external;

    /**
     * @dev Unauthorizes `who` to call `what` on `where`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, address where, bytes4 what) external;
}