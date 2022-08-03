/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: MaxAccess.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Access control based off EIP 173/roles from OZ
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IOwnerV2.sol";
import "./IDeveloperV2.sol";
import "./IRole.sol";
import "../lib/Roles.sol";
import "../errors/MaxErrors.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract MaxAccess is MaxErrors
                             , IRole
                             , IOwnerV2
                             , IDeveloperV2 {
  using Roles for Roles.Role;

  Roles.Role private contractRoles;

  // bytes4 caluclated as follows
  // bytes4(keccak256(bytes(signature)))
  // developer() => 0xca4b208b
  // owner() => 0x8da5cb5b
  // admin() => 0xf851a440
  // was using trailing () for caluclations

  bytes4 constant private DEVS = 0xca4b208b;
  bytes4 constant private PENDING_DEVS = 0xca4b208a; // DEVS - 1
  bytes4 constant private OWNERS = 0x8da5cb5b;
  bytes4 constant private PENDING_OWNERS = 0x8da5cb5a; // OWNERS - 1
  bytes4 constant private ADMIN = 0xf851a440;

  // @dev you can sub your own address here... this is MaxFlowO2.eth
  // these are for displays anyways, and init().
  address private TheDev = address(0x4CE69fd760AD0c07490178f9a47863Dc0358cCCD);
  address private TheOwner = address(0x44f750eB065596c150B3479B1DF6957da300a332);

  constructor() {
    // supercedes all the logic below
    contractRoles.add(ADMIN, address(this));
    _grantRole(ADMIN, TheDev);
    _grantRole(OWNERS, TheOwner);
    _grantRole(DEVS, TheDev);
  }

  // modifiers
  modifier onlyRole(bytes4 role) {
    if (_checkRole(role, msg.sender) || _checkRole(ADMIN, msg.sender)) {
      _;
    } else {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "MaxAccess: You are a not an ",
                    Strings.toHexString(uint32(role), 4),
                    " or ",
                    Strings.toHexString(uint32(ADMIN), 4),
                    " ",
                    Strings.toHexString(uint160(msg.sender), 20)
                  )
                )
      });
    }
  }

  modifier onlyDev() {
    if (!_checkRole(DEVS, msg.sender)) {
      revert Unauthorized();
    }
    _;
  }

  modifier onlyOwner() {
    if (!_checkRole(OWNERS, msg.sender)) {
      revert Unauthorized();
    }
    _;
  }

  // internal logic first 
  // (sets the tone later, and for later contracts)

  // @dev: this is the bool for checking if the account has a role via lib roles.sol
  // @param role: bytes4 of the role to check for
  // @param account: address of account to check
  // @return: bool true/false
  function _checkRole(
    bytes4 role
  , address account
  ) internal
    view
    virtual
    returns (bool) {
    return contractRoles.has(role, account);
  }

  // @dev: this is the internal to grant roles
  // @param role: bytes4 of the role
  // @param account: address of account to add
  function _grantRole(
    bytes4 role
  , address account
  ) internal
    virtual {
    contractRoles.add(role, account);
  }

  // @dev: this is the internal to revoke roles
  // @param role: bytes4 of the role
  // @param account: address of account to remove
  function _revokeRole(
    bytes4 role
  , address account
  ) internal
    virtual {
    contractRoles.remove(role, account);
  }

  // @dev: Returns `true` if `account` has been granted `role`.
  // @param role: Bytes4 of a role
  // @param account: Address to check
  // @return: bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    virtual
    override
    returns (bool) {
    return _checkRole(role, account);
  }

  // @dev: Returns the admin role that controls a role
  // @param role: Role to check
  // @return: admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view
    virtual
    override
    returns (bytes4) {
    return ADMIN;
  }

  // @dev: Grants `role` to `account`
  // @param role: Bytes4 of a role
  // @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external
    virtual
    override 
    onlyRole(role) {

    if (role == PENDING_DEVS) {
      // locks out pending devs from mass swapping roles
      if (_checkRole(PENDING_DEVS, msg.sender)) {
        revert MaxSplaining({
          reason: string(
                    abi.encodePacked(
                      "MaxAccess: You are a pending developer() ",
                      Strings.toHexString(uint160(msg.sender), 20),
                      " you can not grant role ",
                      Strings.toHexString(uint32(role), 4),
                      " to ",
                      Strings.toHexString(uint160(account), 20)
                    )
                  )
        });
      }
    }

    if (role == PENDING_OWNERS) {
      // locks out pending owners from mass swapping roles
      if (_checkRole(PENDING_OWNERS, msg.sender)) {
        revert MaxSplaining({
          reason: string(
                    abi.encodePacked(
                      "MaxAccess: You are a pending owner() ",
                      Strings.toHexString(uint160(msg.sender), 20),
                      " you can not grant role ",
                      Strings.toHexString(uint32(role), 4),
                      " to ",
                      Strings.toHexString(uint160(account), 20)
                    )
                  )
        });
      }
    }

    _grantRole(role, account);
  }

  // @dev: Revokes `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    virtual
    override
    onlyRole(role) {

    if (role == PENDING_DEVS) {
      // locks out pending devs from mass swapping roles
      if (account != msg.sender) {
        revert MaxSplaining({
          reason: string(
                    abi.encodePacked(
                      "MaxAccess: You are a pending developer() ",
                      Strings.toHexString(uint160(msg.sender), 20),
                      " you can not revoke role ",
                      Strings.toHexString(uint32(role), 4),
                      " to ",
                      Strings.toHexString(uint160(account), 20)
                    )
                  )
        });
      }
    }

    if (role == PENDING_OWNERS) {
      // locks out pending owners from mass swapping roles
      if (account != msg.sender) {
        revert MaxSplaining({
          reason: string(
                    abi.encodePacked(
                      "MaxAccess: You are a pending owner() ",
                      Strings.toHexString(uint160(msg.sender), 20),
                      " you can not revoke role ",
                      Strings.toHexString(uint32(role), 4),
                      " to ",
                      Strings.toHexString(uint160(account), 20)
                    )
                  )
        });
      }
    }
    _revokeRole(role, account);
  }

  // @dev: Renounces `role` from `account`
  // @param role: Bytes4 of a role
  // @param account: account to renounce role from
  function renounceRole(
    bytes4 role
  ) external
    virtual
    override 
    onlyRole(role) {
    address user = msg.sender;
    _revokeRole(role, user);
  }

  // Now the classic onlyDev() + "V2" suggested by auditors

  // @dev: Classic "EIP-173" but for onlyDev()
  // @return: Developer of contract
  function developer()
    external
    view
    virtual
    override
    returns (address) {
    return TheDev;
  }

  // @dev: This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    virtual
    override 
    onlyRole(DEVS) {
    address user = msg.sender;
    _revokeRole(DEVS, user);
  }

  // @dev: Classic "EIP-173" but for onlyDev()
  // @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    virtual
    override 
    onlyRole(DEVS) {
    address user = msg.sender;
    _grantRole(DEVS, newDeveloper);
    _revokeRole(DEVS, user);
  }

  // @dev: This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external
    virtual
    override 
    onlyRole(PENDING_DEVS) {
    address user = msg.sender;
    _revokeRole(PENDING_DEVS, user);
    _grantRole(DEVS, user);
  }

  // @dev: This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external
    virtual
    override 
    onlyRole(PENDING_DEVS) {
    address user = msg.sender;
    _revokeRole(PENDING_DEVS, user);
  }

  // @dev: This starts the push-pull method of onlyDev()
  // @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external
    virtual
    override
    onlyRole(DEVS) {
    _grantRole(PENDING_DEVS, newDeveloper);
  }

  // @dev: This changes the display of developer()
  // @param newDisplay: new display addrss for developer()
  function setDeveloper(
    address newDisplay
  ) external
    onlyDev() {
    if (!_checkRole(DEVS, newDisplay)) {
        revert MaxSplaining({
          reason: string(
                    abi.encodePacked(
                      "MaxAccess: The address ",
                      Strings.toHexString(uint160(newDisplay), 20),
                      " is not a developer and does not have the role ",
                      Strings.toHexString(uint32(DEVS), 4),
                      " there ",
                      Strings.toHexString(uint160(msg.sender), 20)
                    )
                  )
        });
    }
    TheDev = newDisplay;
  }

  // Now the classic onlyOwner() + "V2" suggested by auditors

  // @dev: Classic "EIP-173" getter for owner()
  // @return: owner of contract
  function owner()
    external
    view
    virtual
    override
    returns (address) {
    return TheOwner;
  }

   // @dev: This renounces your role as onlyOwner()
  function renounceOwnership()
    external
    virtual
    override
    onlyRole(OWNERS) {
    address user = msg.sender;
    _revokeRole(OWNERS, user);
  }

  // @dev: Classic "EIP-173" but for onlyOwner()
  // @param newOwner: addres of new pending Developer role
  function transferOwnership(
    address newOwner
  ) external
    virtual
    override
    onlyRole(OWNERS) {
    address user = msg.sender;
    _grantRole(OWNERS, newOwner);
    _revokeRole(OWNERS, user);
  }

  // @dev: This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external
    virtual
    override
    onlyRole(PENDING_OWNERS) {
    address user = msg.sender;
    _revokeRole(PENDING_OWNERS, user);
    _grantRole(OWNERS, user);
  }

  // @dev: This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external
    virtual
    override
    onlyRole(PENDING_OWNERS) {
    address user = msg.sender;
    _revokeRole(PENDING_OWNERS, user);
  }

  // @dev: This starts the push-pull method of onlyOwner()
  // @param newOwner: addres of new pending developer role
  function pushOwnership(
    address newOwner
  ) external
    virtual
    override
    onlyRole(OWNERS) {
    _grantRole(PENDING_OWNERS, newOwner);
  }

  // @dev: This changes the display of Ownership()
  // @param newDisplay: new display addrss for Ownership()
  function setOwner(
    address newDisplay
  ) external
    onlyOwner() {
    if (!_checkRole(OWNERS, newDisplay)) {
        revert MaxSplaining({
          reason: string(
                    abi.encodePacked(
                      "MaxAccess: The address ",
                      Strings.toHexString(uint160(newDisplay), 20),
                      " is not an owner and does not have the role ",
                      Strings.toHexString(uint32(OWNERS), 4),
                      " there ",
                      Strings.toHexString(uint160(msg.sender), 20)
                    )
                  )
        });
    }
    TheOwner = newDisplay;
  }
}