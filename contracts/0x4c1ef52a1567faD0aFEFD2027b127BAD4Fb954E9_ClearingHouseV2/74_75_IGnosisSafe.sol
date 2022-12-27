// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGnosisSafe {
  enum Operation {
    Call,
    DelegateCall
  }

  function getThreshold() external view returns (uint256);

  function isOwner(address owner) external view returns (bool);

  /// @dev Returns array of owners.
  /// @return Array of Safe owners.
  function getOwners() external view returns (address[] memory);

  function isModuleEnabled(address module) external view returns (bool);

  /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
  ///      Note: The fees are always transferred, even if the user transaction fails.
  /// @param to Destination address of Safe transaction.
  /// @param value Ether value of Safe transaction.
  /// @param data Data payload of Safe transaction.
  /// @param operation Operation type of Safe transaction.
  /// @param safeTxGas Gas that should be used for the Safe transaction.
  /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
  /// @param gasPrice Gas price that should be used for the payment calculation.
  /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
  /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
  /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
  function execTransaction(
    address to,
    uint256 value,
    bytes calldata data,
    Operation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) external payable returns (bool success);

  /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
  ///      This can only be done via a Safe transaction.
  /// @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
  /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
  /// @param owner Owner address to be removed.
  /// @param _threshold New threshold.
  function removeOwner(
    address prevOwner,
    address owner,
    uint256 _threshold
  ) external;

  /// @dev Setup function sets initial storage of contract.
  /// @param _owners List of Safe owners.
  /// @param _threshold Number of required confirmations for a Safe transaction.
  /// @param to Contract address for optional delegate call.
  /// @param data Data payload for optional delegate call.
  /// @param fallbackHandler Handler for fallback calls to this contract
  /// @param paymentToken Token that should be used for the payment (0 is ETH)
  /// @param payment Value that should be paid
  /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
  function setup(
    address[] calldata _owners,
    uint256 _threshold,
    address to,
    bytes calldata data,
    address fallbackHandler,
    address paymentToken,
    uint256 payment,
    address payable paymentReceiver
  ) external;
}