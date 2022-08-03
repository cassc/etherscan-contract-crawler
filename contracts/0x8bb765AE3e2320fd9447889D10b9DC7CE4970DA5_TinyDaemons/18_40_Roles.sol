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
 * @author: OpenZeppelin, rewrite by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Library for MaxAcess.sol
 * @dev: Rewritten for gas optimization, and from abstract -> library, added
 * multiple types instead of a solo role.
 * Original source:
 * https://github.com/hiddentao/openzeppelin-solidity/blob/master/contracts/access/Roles.sol
 *
 * Include with 'using Roles for Roles.Role;'
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library Roles {

  // @dev: this is Unauthorized(), basically a catch all, zero description
  // @notice: 0x82b42900 bytes4 of this
  error Unauthorized();

  // @dev: this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  // @param reason: Use the "Contract name: error"
  // @notice: 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  event RoleChanged(bytes4 _type, address _user, bool _status); // 0x0baaa7ab

  struct Role {
    mapping(address => mapping(bytes4 => bool)) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, bytes4 _type, address account) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (has(role, _type, account)) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Lib Roles: ",
                    Strings.toHexString(uint160(account), 20),
                    " already has role ",
                    Strings.toHexString(uint32(_type), 4)
                  )
                )
      });
    }
    role.bearer[account][_type] = true;
    emit RoleChanged(_type, account, true);
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, bytes4 _type, address account) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (!has(role, _type, account)) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Lib Roles: ",
                    Strings.toHexString(uint160(account), 20),
                    " does not have role ",
                    Strings.toHexString(uint32(_type), 4)
                  )
                )
      });
    }
    role.bearer[account][_type] = false;
    emit RoleChanged(_type, account, false);
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, bytes4 _type, address account)
    internal
    view
    returns (bool)
  {
    if (account == address(0)) {
      revert Unauthorized();
    }
    return role.bearer[account][_type];
  }
}