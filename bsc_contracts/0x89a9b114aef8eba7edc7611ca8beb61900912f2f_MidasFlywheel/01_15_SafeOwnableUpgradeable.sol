// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 * @dev Ownable extension that requires a two-step process of setting the pending owner and the owner accepting it.
 * @notice Existing OwnableUpgradeable contracts cannot be upgraded due to the extra storage variable
 * that will shift the other.
 */
abstract contract SafeOwnableUpgradeable is OwnableUpgradeable {
  /**
   * @notice Pending owner of this contract
   */
  address public pendingOwner;

  function __SafeOwnable_init() internal onlyInitializing {
    __Ownable_init();
  }

  struct AddressSlot {
    address value;
  }

  modifier onlyOwnerOrAdmin() {
    bool isOwner = owner() == _msgSender();
    if (!isOwner) {
      bytes32 _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
      AddressSlot storage adminSlot;
      assembly {
        adminSlot.slot := _ADMIN_SLOT
      }
      address admin = adminSlot.value;
      bool isAdmin = admin == _msgSender();
      require(isAdmin, "Ownable: caller is neither the owner nor the admin");
    }
    _;
  }

  /**
   * @notice Emitted when pendingOwner is changed
   */
  event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

  /**
   * @notice Emitted when pendingOwner is accepted, which means owner is updated
   */
  event NewOwner(address oldOwner, address newOwner);

  /**
   * @notice Begins transfer of owner rights. The newPendingOwner must call `_acceptOwner` to finalize the transfer.
   * @dev Owner function to begin change of owner. The newPendingOwner must call `_acceptOwner` to finalize the transfer.
   * @param newPendingOwner New pending owner.
   */
  function _setPendingOwner(address newPendingOwner) public onlyOwner {
    // Save current value, if any, for inclusion in log
    address oldPendingOwner = pendingOwner;

    // Store pendingOwner with value newPendingOwner
    pendingOwner = newPendingOwner;

    // Emit NewPendingOwner(oldPendingOwner, newPendingOwner)
    emit NewPendingOwner(oldPendingOwner, newPendingOwner);
  }

  /**
   * @notice Accepts transfer of owner rights. msg.sender must be pendingOwner
   * @dev Owner function for pending owner to accept role and update owner
   */
  function _acceptOwner() public {
    // Check caller is pendingOwner and pendingOwner ≠ address(0)
    require(msg.sender == pendingOwner, "not the pending owner");

    // Save current values for inclusion in log
    address oldOwner = owner();
    address oldPendingOwner = pendingOwner;

    // Store owner with value pendingOwner
    _transferOwnership(pendingOwner);

    // Clear the pending value
    pendingOwner = address(0);

    emit NewOwner(oldOwner, pendingOwner);
    emit NewPendingOwner(oldPendingOwner, pendingOwner);
  }

  function renounceOwnership() public override onlyOwner {
    // do not remove this overriding fn
    revert("not used anymore");
  }

  function transferOwnership(address newOwner) public override onlyOwner {
    // do not remove this overriding fn
    revert("not used anymore");
  }
}