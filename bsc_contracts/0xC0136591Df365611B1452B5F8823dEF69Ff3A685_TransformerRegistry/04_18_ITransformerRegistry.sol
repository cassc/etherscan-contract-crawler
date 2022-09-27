// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './ITransformer.sol';

/**
 * @title A registry for all existing transformers
 * @notice This contract will contain all registered transformers and act as proxy. When called
 *         the registry will find the corresponding transformer and delegate the call to it. If no
 *         transformer is found, then it will fail
 */
interface ITransformerRegistry is ITransformer {
  /// @notice An association between a transformer, and some of its dependentes
  struct TransformerRegistration {
    address transformer;
    address[] dependents;
  }

  /**
   * @notice Thrown when trying to register a dependent to an address that is not a transformer
   * @param account The account that was not a transformer
   */
  error AddressIsNotTransformer(address account);

  /**
   * @notice Thrown when trying to execute an action with a dependent that has no transformer
   *          associated
   * @param dependent The dependent that didn't have a transformer
   */
  error NoTransformerRegistered(address dependent);

  /**
   * @notice Emitted when new dependents are registered
   * @param registrations The dependents that were registered
   */
  event TransformersRegistered(TransformerRegistration[] registrations);

  /**
   * @notice Emitted when dependents are removed from the registry
   * @param dependents The dependents that were removed
   */
  event TransformersRemoved(address[] dependents);

  /**
   * @notice Returns the registered transformer for the given dependents
   * @param dependents The dependents to get the transformer for
   * @return The registered transformers, or the zero address if there isn't any
   */
  function transformers(address[] calldata dependents) external view returns (ITransformer[] memory);

  /**
   * @notice Sets a new registration for the given dependents
   * @dev Can only be called by admin
   * @param registrations The associations to register
   */
  function registerTransformers(TransformerRegistration[] calldata registrations) external;

  /**
   * @notice Removes registration for the given dependents
   * @dev Can only be called by admin
   * @param dependents The associations to remove
   */
  function removeTransformers(address[] calldata dependents) external;

  /**
   * @notice Executes a transformation to the underlying tokens, by taking the caller's entire
   *         dependent balance. This is meant to be used as part of a multi-hop swap
   * @dev This function was made payable, so that it could be multicalled when msg.value > 0
   * @param dependent The address of the dependent token
   * @param recipient The address that would receive the underlying tokens
   * @param minAmountOut The minimum amount of underlying that the caller expects to get. Will fail
   *                     if less is received. As a general rule, the underlying tokens should
   *                     be provided in the same order as `getUnderlying` returns them
   * @param deadline A deadline when the transaction becomes invalid
   * @return The transformed amount in each of the underlying tokens
   */
  function transformAllToUnderlying(
    address dependent,
    address recipient,
    UnderlyingAmount[] calldata minAmountOut,
    uint256 deadline
  ) external payable returns (UnderlyingAmount[] memory);

  /**
   * @notice Executes a transformation to the dependent token, by taking the caller's entire
   *         underlying balance. This is meant to be used as part of a multi-hop swap
   * @dev This function will not work when the underlying token is ETH/MATIC/BNB, since it can't be taken from the caller
   *      This function was made payable, so that it could be multicalled when msg.value > 0
   * @param dependent The address of the dependent token
   * @param recipient The address that would receive the dependent tokens
   * @param minAmountOut The minimum amount of dependent that the caller expects to get. Will fail
   *                     if less is received
   * @param deadline A deadline when the transaction becomes invalid
   * @return amountDependent The transformed amount in the dependent token
   */
  function transformAllToDependent(
    address dependent,
    address recipient,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable returns (uint256 amountDependent);
}