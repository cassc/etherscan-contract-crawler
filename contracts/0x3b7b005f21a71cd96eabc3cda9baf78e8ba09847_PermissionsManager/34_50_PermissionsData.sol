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

/**
 * @dev Permission
 * @param what Function selector to be referred
 * @param who Address to be referred
 */
struct Permission {
    bytes4 what;
    address who;
}

/**
 * @dev Permission change
 * @param grant Whether the permission should be granted (authorize) or revoked (unauthorize)
 * @param permissions Permission to be changed
 */
struct PermissionChange {
    bool grant;
    Permission permission;
}

/**
 * @dev Permission change request
 * @param target Address of the contract to be affected
 * @param changes List of permission changes to be performed
 */
struct PermissionChangeRequest {
    IAuthorizer target;
    PermissionChange[] changes;
}