// SPDX-License-Identifier: MIT
// Halborn (Ownable.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed through a two-step process where the owner nominates an
 * account and the nominated account needs to call the `acceptOwnership()`
 * function for the transfer of the ownership to fully succeed. This ensures the
 * nominated EOA account is a valid and active account.
 *
 * `renounceOwnership()` function is disabled by default. Remove the comments
 * in order to enable the function.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;
  address private _ownerCandidate;

  event OwnerUpdated(address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _owner = _msgSender();
    emit OwnerUpdated(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Returns the address of the new owner candidate.
   */
  function ownerCandidate() external view virtual returns (address) {
    return _ownerCandidate;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Proposes a new owner. Can only be called by the current
   * owner of the contract.
   */
  function proposeOwner(address newOwner) external onlyOwner {
    if (newOwner == address(0x0)) revert('Address cannot be zero');

    _ownerCandidate = newOwner;
  }

  /**
   * @dev Assigns the ownership of the contract to _ownerCandidate.
   * Can only be called by the _ownerCandidate.
   */
  function acceptOwnership() external {
    if (_ownerCandidate != msg.sender) revert('You are not the owner');
    _owner = msg.sender;
    emit OwnerUpdated(msg.sender);
  }

  /**
   * @dev Cancels the new owner proposal.
   * Can only be called by the _ownerCandidate or the current owner
   * of the contract.
   */
  function cancelOwnerProposal() external {
    if (_ownerCandidate != msg.sender && _owner != msg.sender) revert('You are not the owner');
    _ownerCandidate = address(0x0);
  }

  /**
    Disabled by default:

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    */
}