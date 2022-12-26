/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Roles.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Library for MaxAcess.sol
 * @custom:error-code Roles:1 User has role already
 * @custom:error-code Roles:2 User does not have role to revoke
 * @custom:change-log custom errors added above
 * @custom:change-log cleaned up variables
 * @custom:change-log internal -> internal/internal
 *
 * Include with 'using Roles for Roles.Role;'
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

library Roles {

  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal ADMIN = 0xf851a440;

  struct Role {
    mapping(address => mapping(bytes4 => bool)) bearer;
    address owner;
    address developer;
    address admin;
  }

  event RoleChanged(bytes4 _role, address _user, bool _status);
  event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event DeveloperTransferred(address indexed previousDeveloper, address indexed newDeveloper);

  error Unauthorized();
  error MaxSplaining(string reason);

  function add(
    Role storage role
  , bytes4 userRole
  , address account
  ) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (has(role, userRole, account)) {
      revert MaxSplaining({
        reason: "Roles:1"
      });
    }
    role.bearer[account][userRole] = true;
    emit RoleChanged(userRole, account, true);
  }

  function remove(
    Role storage role
  , bytes4 userRole
  , address account
  ) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (!has(role, userRole, account)) {
      revert MaxSplaining({
        reason: "Roles:2"
      });
    }
    role.bearer[account][userRole] = false;
    emit RoleChanged(userRole, account, false);
  }

  function has(
    Role storage role
  , bytes4  userRole
  , address account
  ) internal
    view
    returns (bool) {
    if (account == address(0)) {
      revert Unauthorized();
    }
    return role.bearer[account][userRole];
  }

  function setAdmin(
    Role storage role
  , address account
  ) internal {
    if (has(role, ADMIN, account)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else if (account == address(0)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else {
      revert Unauthorized();
    }
  }

  function setDeveloper(
    Role storage role
  , address account
  ) internal {
    if (has(role, DEVS, account)) {
      address old = role.developer;
      role.developer = account;
      emit DeveloperTransferred(old, role.developer);
    } else if (account == address(0)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else {
      revert Unauthorized();
    }
  }

  function setOwner(
    Role storage role
  , address account
  ) internal {
    if (has(role, OWNERS, account)) {
      address old = role.owner;
      role.owner = account;
      emit OwnershipTransferred(old, role.owner);
    } else if (account == address(0)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else {
      revert Unauthorized();
    }
  }

  function getAdmin(
    Role storage role
  ) internal 
    view
    returns (address) {
    return role.admin;
  }

  function getDeveloper(
    Role storage role
  ) internal
    view
    returns (address) {
    return role.developer;
  }

  function getOwner(
    Role storage role
  ) internal
    view
    returns (address) {
    return role.owner;
  }
}