/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: Contract Roles Standard
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Interface for MaxAccess version of Roles
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

import "../../eip/165/IERC165.sol";

interface IRoles is IERC165 {

  /// @dev Returns `true` if `account` has been granted `role`.
  /// @param role: Bytes4 of a role
  /// @param account: Address to check
  /// @return bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool);

  /// @dev Returns the admin role that controls a role
  /// @param role: Role to check
  /// @return admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4);

  /// @dev Grants `role` to `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external;

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external;

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external;
}