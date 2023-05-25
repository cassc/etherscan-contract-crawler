// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title PausableUpgradableProxy
 * @author Railgun Contributors
 * @notice Delegates calls to implementation address
 * @dev Calls are reverted if the contract is paused
 */
contract PausableUpgradableProxy {
  // Storage slot locations
  bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
  bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
  bytes32 private constant PAUSED_SLOT = bytes32(uint256(keccak256("eip1967.proxy.paused")) - 1);

  // Events
  event ProxyUpgrade(address previousImplementation, address newImplementation);
  event ProxyOwnershipTransfer(address previousOwner, address newOwner);
  event ProxyPause();
  event ProxyUnpause();

  /**
   * @notice Sets initial specified admin value
   * Implementation is set as 0x0 and contract is created as paused
   * @dev Implementation must be set before unpausing
   */

  constructor(address _admin) {
    // Set initial value for admin
    StorageSlot.getAddressSlot(ADMIN_SLOT).value = _admin;

    // Explicitly initialize implementation as 0
    StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = address(0);

    // Explicitly initialize as paused
    StorageSlot.getBooleanSlot(PAUSED_SLOT).value = true;
  }

  /**
   * @notice Reverts if proxy is paused
   */

  modifier notPaused() {
    // Revert if the contract is paused
    require(!StorageSlot.getBooleanSlot(PAUSED_SLOT).value, "Proxy: Contract is paused");
    _;
  }

  /**
   * @notice Delegates call to implementation
   */

  function delegate() internal notPaused {
    // Get implementation
    address implementation = StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;

    // Check that implementation exists
    require(Address.isContract(implementation), "Proxy: Implementation doesn't exist");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @notice Prevents calls unless caller is owner
   * @dev This should be on all external/public functions that aren't the fallback
   */

  modifier onlyOwner() {
    if (msg.sender == StorageSlot.getAddressSlot(ADMIN_SLOT).value) {
      _;
    } else {
      // Redirect to delegate if caller isn't owner
      delegate();
    }
  }

  /**
   * @notice fallback function that delegates calls with calladata
   */
  fallback() external payable {
    delegate();
  }

  /**
   * @notice fallback function that delegates calls with no calladata
   */
  receive() external payable {
    delegate();
  }

  /**
   * @notice Transfers ownership to new address
   * @param _newOwner - Address to transfer ownership to
   */
  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Proxy: Preventing potential accidental burn");

    // Get admin slot
    StorageSlot.AddressSlot storage admin = StorageSlot.getAddressSlot(ADMIN_SLOT);

    // Emit event
    emit ProxyOwnershipTransfer(admin.value, _newOwner);

    // Store new admin
    admin.value = _newOwner;
  }

  /**
   * @notice Upgrades implementation
   * @param _newImplementation - Address of the new implementation
   */
  function upgrade(address _newImplementation) external onlyOwner {
    // Get implementation slot
    StorageSlot.AddressSlot storage implementation = StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT);

    // If new implementation is identical to old, skip
    if (implementation.value != _newImplementation) {
      // Emit event
      emit ProxyUpgrade(implementation.value, _newImplementation);

      // Store new implementation
      implementation.value = _newImplementation;
    }
  }

  /**
   * @notice Pauses contract
   */
  function pause() external onlyOwner  {
    // Get paused slot
    StorageSlot.BooleanSlot storage paused = StorageSlot.getBooleanSlot(PAUSED_SLOT);

    // If not already paused, pause
    if (!paused.value) {
      // Set paused to true
      paused.value = true;

      // Emit paused event
      emit ProxyPause();
    }
  }

  /**
   * @notice Unpauses contract
   */
  function unpause() external onlyOwner {
    // Get paused slot
    StorageSlot.BooleanSlot storage paused = StorageSlot.getBooleanSlot(PAUSED_SLOT);

    // If already unpaused, do nothing
    if (paused.value) {
      // Set paused to true
      paused.value = false;

      // Emit paused event
      emit ProxyUnpause();
    }
  }
}