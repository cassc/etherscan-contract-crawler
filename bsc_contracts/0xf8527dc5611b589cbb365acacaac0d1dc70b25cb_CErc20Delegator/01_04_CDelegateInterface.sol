// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract CDelegationStorage {
  /**
   * @notice Implementation address for this contract
   */
  address public implementation;
}

abstract contract CDelegateInterface is CDelegationStorage {
  /**
   * @notice Emitted when implementation is changed
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementationSafe(
    address implementation_,
    bool allowResign,
    bytes calldata becomeImplementationData
  ) external virtual;

  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @dev Should revert if any issues arise which make it unfit for delegation
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes calldata data) public virtual;

  /**
   * @notice Function called before all delegator functions
   * @dev Checks comptroller.autoImplementation and upgrades the implementation if necessary
   */
  function _prepare() external payable virtual;

  function contractType() external virtual returns (string memory);
}