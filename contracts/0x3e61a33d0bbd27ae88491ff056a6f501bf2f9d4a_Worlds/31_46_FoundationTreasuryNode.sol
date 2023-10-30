// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/internal/roles/IAdminRole.sol";
import "../../interfaces/internal/roles/IOperatorRole.sol";

error FoundationTreasuryNode_Address_Is_Not_A_Contract();
error FoundationTreasuryNode_Caller_Not_Admin();

/**
 * @title Stores a reference to Foundation's treasury contract for other mixins to leverage.
 * @notice The treasury collects fees and defines admin/operator roles.
 * @author batu-inal & HardlyDifficult
 */
abstract contract FoundationTreasuryNode {
  using AddressUpgradeable for address payable;

  /// @notice The address of the treasury contract.
  address payable private immutable treasury;

  /// @notice Requires the caller is a Foundation admin.
  modifier onlyFoundationAdmin() {
    if (!IAdminRole(treasury).isAdmin(msg.sender)) {
      revert FoundationTreasuryNode_Caller_Not_Admin();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Assigns the treasury contract address.
   */
  constructor(address payable _treasury) {
    if (!_treasury.isContract()) {
      revert FoundationTreasuryNode_Address_Is_Not_A_Contract();
    }

    treasury = _treasury;
  }

  /**
   * @notice Gets the Foundation treasury contract.
   * @dev This call is used in the royalty registry contract.
   * @return treasuryAddress The address of the Foundation treasury contract.
   */
  function getFoundationTreasury() public view returns (address payable treasuryAddress) {
    treasuryAddress = treasury;
  }

  // This mixin uses 0 slots.
}