/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IRole.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Interface for MaxAccess version of roles
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRole is IERC165 {

  // @dev: Returns `true` if `account` has been granted `role`.
  // @param role: Bytes4 of a role
  // @param account: Address to check
  // @return: bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool);

  // @dev: Returns the admin role that controls a role
  // @param role: Role to check
  // @return: admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4);

  // @dev: Grants `role` to `account`
  // @param role: Bytes4 of a role
  // @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external;

  // @dev: Revokes `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external;

  // @dev: Renounces `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to renounce role from
  function renounceRole(
    bytes4 role
  ) external;
}