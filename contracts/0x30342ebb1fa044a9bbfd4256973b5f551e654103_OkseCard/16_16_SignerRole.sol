//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    // require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor() {}

  // solhint-disable-previous-line no-empty-blocks

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract SignerRole is Context {
  using Roles for Roles.Role;

  event SignerAdded(address indexed account);
  event SignerRemoved(address indexed account);

  Roles.Role private _signers;

  constructor(address _signer) {
    _addSigner(_signer);
  }

  modifier onlySigner() {
    require(
      isSigner(_msgSender()),
      "SignerRole: caller does not have the Signer role"
    );
    _;
  }

  function isSigner(address account) public view returns (bool) {
    return _signers.has(account);
  }

  function _addSigner(address account) internal {
    _signers.add(account);
    emit SignerAdded(account);
  }

  function _removeSigner(address account) internal {
    _signers.remove(account);
    emit SignerRemoved(account);
  }
}