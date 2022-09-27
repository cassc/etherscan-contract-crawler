// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @notice This contract will act as a registry to allowlist swappers. Different contracts from the Mean
 *         ecosystem will ask this contract if an address is a valid swapper or not
 *         In some cases, swappers have supplementary allowance targets that need ERC20 approvals. We
 *         will also track those here
 */
interface ISwapperRegistry {
  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when trying to remove an account from the swappers list, when it wasn't there before
  error AccountIsNotSwapper(address account);

  /**
   * @notice Thrown when trying to remove an account from the supplementary allowance target list,
   *         when it wasn't there before
   */
  error AccountIsNotSupplementaryAllowanceTarget(address account);

  /// @notice Thrown when trying to mark an account as swapper or allowance target, but it already has a role assigned
  error AccountAlreadyHasRole(address account);

  /**
   * @notice Emitted when swappers are removed from the allowlist
   * @param swappers The swappers that were removed
   */
  event RemoveSwappersFromAllowlist(address[] swappers);

  /**
   * @notice Emitted when new swappers are added to the allowlist
   * @param swappers The swappers that were added
   */
  event AllowedSwappers(address[] swappers);

  /**
   * @notice Emitted when new supplementary allowance targets are are added to the allowlist
   * @param allowanceTargets The allowance targets that were added
   */
  event AllowedSupplementaryAllowanceTargets(address[] allowanceTargets);

  /**
   * @notice Emitted when supplementary allowance targets are removed from the allowlist
   * @param allowanceTargets The allowance targets that were removed
   */
  event RemovedAllowanceTargetsFromAllowlist(address[] allowanceTargets);

  /**
   * @notice Returns whether a given account is allowlisted for swaps
   * @param account The address to check
   * @return Whether it is allowlisted for swaps
   */
  function isSwapperAllowlisted(address account) external view returns (bool);

  /**
   * @notice Returns whether a given account is a valid allowance target. This would be true
   *         if the account is either a swapper, or a supplementary allowance target
   * @param account The address to check
   * @return Whether it is a valid allowance target
   */
  function isValidAllowanceTarget(address account) external view returns (bool);

  /**
   * @notice Adds a list of swappers to the allowlist
   * @dev Can only be called by users with the admin role
   * @param swappers The list of swappers to add
   */
  function allowSwappers(address[] calldata swappers) external;

  /**
   * @notice Removes the given swappers from the allowlist
   * @dev Can only be called by users with the admin role
   * @param swappers The list of swappers to remove
   */
  function removeSwappersFromAllowlist(address[] calldata swappers) external;

  /**
   * @notice Adds a list of supplementary allowance targets to the allowlist
   * @dev Can only be called by users with the admin role
   * @param allowanceTargets The list of allowance targets to add
   */
  function allowSupplementaryAllowanceTargets(address[] calldata allowanceTargets) external;

  /**
   * @notice Removes the given allowance targets from the allowlist
   * @dev Can only be called by users with the admin role
   * @param allowanceTargets The list of allowance targets to remove
   */
  function removeSupplementaryAllowanceTargetsFromAllowlist(address[] calldata allowanceTargets) external;
}