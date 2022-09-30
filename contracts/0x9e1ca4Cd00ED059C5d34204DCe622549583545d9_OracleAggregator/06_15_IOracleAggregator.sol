// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './ITokenPriceOracle.sol';

/**
 * @title An implementation of `ITokenPriceOracle` that aggregates two or more oracles. It's important to
 *        note that this oracle is permissioned. Admins can determine available oracles and they can
 *        also force an oracle for a specific pair
 * @notice This oracle will use two or more oracles to support price quotes
 */
interface IOracleAggregator is ITokenPriceOracle {
  /// @notice An oracle's assignment for a specific pair
  struct OracleAssignment {
    // The oracle's address
    ITokenPriceOracle oracle;
    // Whether the oracle was forced by an admin. If forced, only an admin can modify it
    bool forced;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /**
   * @notice Thrown when trying to register an address that is not an oracle
   * @param notOracle The address that was not a oracle
   */
  error AddressIsNotOracle(address notOracle);

  /**
   * @notice Emitted when the list of oracles is updated
   * @param oracles The new list of oracles
   */
  event OracleListUpdated(address[] oracles);

  /**
   * @notice Emitted when an oracle is assigned to a pair
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param oracle The oracle that was assigned to the pair
   */
  event OracleAssigned(address tokenA, address tokenB, ITokenPriceOracle oracle);

  /**
   * @notice Returns the assigned oracle (or the zero address if there isn't one) for the given pair
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return The assigned oracle for the given pair
   */
  function assignedOracle(address tokenA, address tokenB) external view returns (OracleAssignment memory);

  /**
   * @notice Returns whether this oracle can support the given pair of tokens
   * @return Whether the given pair of tokens can be supported by the oracle
   */
  function availableOracles() external view returns (ITokenPriceOracle[] memory);

  /**
   * @notice Returns the oracle that would be assigned to the pair if `addOrModifySupportForPair`
   *         was called by the same caller
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return The oracle that would be assigned (or the zero address if none could be assigned)
   */
  function previewAddOrModifySupportForPair(address tokenA, address tokenB) external view returns (ITokenPriceOracle);

  /**
   * @notice Sets a new oracle for the given pair. After it's sent, only other admins will be able
   *         to modify the pair's oracle
   * @dev Can only be called by users with the admin role
   *      tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param oracle The oracle to set
   * @param data Custom data that the oracle might need to operate
   */
  function forceOracle(
    address tokenA,
    address tokenB,
    address oracle,
    bytes calldata data
  ) external;

  /**
   * @notice Sets a new list of oracles to be used by the aggregator
   * @dev Can only be called by users with the admin role
   * @param oracles The new list of oracles to set
   */
  function setAvailableOracles(address[] calldata oracles) external;
}