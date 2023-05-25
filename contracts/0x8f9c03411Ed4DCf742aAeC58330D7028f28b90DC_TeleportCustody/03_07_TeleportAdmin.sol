// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple accounts (admins) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `consumeAuthorization`, which can be applied to your functions to restrict
 * their use to the admins.
 */
contract TeleportAdmin is Ownable {
  // Marks that the contract is frozen or unfrozen (safety kill-switch)
  bool private _isFrozen;

  mapping(address => uint256) private _allowedAmount;

  event AdminUpdated(address indexed account, uint256 allowedAmount);

  // Modifiers

  /**
    * @dev Throw if contract is currently frozen.
    */
  modifier notFrozen() {
    require(
      !_isFrozen,
      "TeleportAdmin: contract is frozen by owner"
    );

    _;
  }

  /**
    * @dev Throw if caller does not have sufficient authorized amount.
    */
  modifier consumeAuthorization(uint256 amount) {
    address sender = _msgSender();
    require(
      allowedAmount(sender) >= amount,
      "TeleportAdmin: caller does not have sufficient authorization"
    );

    _;

    // reduce authorization amount. Underflow cannot occur because we have
    // already checked that admin has sufficient allowed amount.
    _allowedAmount[sender] -= amount;
    emit AdminUpdated(sender, _allowedAmount[sender]);
  }

  /**
    * @dev Checks the authorized amount of an admin account.
    */
  function allowedAmount(address account)
    public
    view
    returns (uint256)
  {
    return _allowedAmount[account];
  }

  /**
    * @dev Returns if the contract is currently frozen.
    */
  function isFrozen()
    public
    view
    returns (bool)
  {
    return _isFrozen;
  }

  /**
    * @dev Owner freezes the contract.
    */
  function freeze()
    public
    onlyOwner
  {
    _isFrozen = true;
  }

  /**
    * @dev Owner unfreezes the contract.
    */
  function unfreeze()
    public
    onlyOwner
  {
    _isFrozen = false;
  }

  /**
    * @dev Updates the admin status of an account.
    * Can only be called by the current owner.
    */
  function updateAdmin(address account, uint256 allowedAmount)
    public
    virtual
    onlyOwner
  {
    emit AdminUpdated(account, allowedAmount);
    _allowedAmount[account] = allowedAmount;
  }

  /**
    * @dev Overrides the inherited method from Ownable.
    * Disable ownership resounce.
    */
  function renounceOwnership()
    public
    override
    onlyOwner
  {
    revert("TeleportAdmin: ownership cannot be renounced");
  }
}