// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol';
import '../ITokenPriceOracle.sol';

interface IUniswapV3Adapter is ITokenPriceOracle {
  /// @notice The initial adapter's configuration
  struct InitialConfig {
    IStaticOracle uniswapV3Oracle;
    uint32 maxPeriod;
    uint32 minPeriod;
    uint32 initialPeriod;
    address superAdmin;
    address[] initialAdmins;
  }

  /// @notice A pair of tokens
  struct Pair {
    address tokenA;
    address tokenB;
  }

  /**
   * @notice Emitted when a new period is set
   * @param period The new period
   */
  event PeriodChanged(uint32 period);

  /**
   * @notice Emitted when a new cardinality per minute is set
   * @param cardinalityPerMinute The new cardinality per minute
   */
  event CardinalityPerMinuteChanged(uint8 cardinalityPerMinute);

  /**
   * @notice Emitted when a new gas cost per cardinality is set
   * @param gasPerCardinality The new gas per cardinality
   */
  event GasPerCardinalityChanged(uint104 gasPerCardinality);

  /**
   * @notice Emitted when a new gas cost to support pools is set
   * @param gasCostToSupportPool The new gas cost
   */
  event GasCostToSupportPoolChanged(uint112 gasCostToSupportPool);

  /**
   * @notice Emitted when the denylist status is updated for some pairs
   * @param pairs The pairs that were updated
   * @param denylisted Whether they will be denylisted or not
   */
  event DenylistChanged(Pair[] pairs, bool[] denylisted);

  /**
   * @notice Emitted when support is updated (added or modified) for a new pair
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param preparedPools The amount of pools that were prepared to support the pair
   */
  event UpdatedSupport(address tokenA, address tokenB, uint256 preparedPools);

  /// @notice Thrown when one of the parameters is the zero address
  error ZeroAddress();

  /// @notice Thrown when trying to set an invalid period
  error InvalidPeriod(uint32 period);

  /// @notice Thrown when trying to set an invalid cardinality
  error InvalidCardinalityPerMinute();

  /// @notice Thrown when trying to set an invalid gas cost per cardinality
  error InvalidGasPerCardinality();

  /// @notice Thrown when trying to set an invalid gas cost to support a pools
  error InvalidGasCostToSupportPool();

  /// @notice Thrown when trying to set a denylist but the given parameters are invalid
  error InvalidDenylistParams();

  /// @notice Thrown when the gas limit is so low that no pools can be initialized
  error GasTooLow();

  /**
   * @notice Returns the address of the Uniswap oracle
   * @dev Cannot be modified
   * @return The address of the Uniswap oracle
   */
  function UNISWAP_V3_ORACLE() external view returns (IStaticOracle);

  /**
   * @notice Returns the maximum possible period
   * @dev Cannot be modified
   * @return The maximum possible period
   */
  function MAX_PERIOD() external view returns (uint32);

  /**
   * @notice Returns the minimum possible period
   * @dev Cannot be modified
   * @return The minimum possible period
   */
  function MIN_PERIOD() external view returns (uint32);

  /**
   * @notice Returns the period used for the TWAP calculation
   * @return The period used for the TWAP
   */
  function period() external view returns (uint32);

  /**
   * @notice Returns the cardinality per minute used for adding support to pairs
   * @return The cardinality per minute used for increase cardinality calculations
   */
  function cardinalityPerMinute() external view returns (uint8);

  /**
   * @notice Returns the approximate gas cost per each increased cardinality
   * @return The gas cost per cardinality increase
   */
  function gasPerCardinality() external view returns (uint104);

  /**
   * @notice Returns the approximate gas cost to add support for a new pool internally
   * @return The gas cost to support a new pool
   */
  function gasCostToSupportPool() external view returns (uint112);

  /**
   * @notice Returns whether the given pair is denylisted or not
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair is denylisted or not
   */
  function isPairDenylisted(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice When a pair is added to the oracle adapter, we will prepare all pools for the pair. Now, it could
   *         happen that certain pools are added for the pair at a later stage, and we can't be sure if those pools
   *         will be configured correctly. So be basically store the pools that ready for sure, and use only those
   *         for quotes. This functions returns this list of pools known to be prepared
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return The list of pools that will be used for quoting
   */
  function getPoolsPreparedForPair(address tokenA, address tokenB) external view returns (address[] memory);

  /**
   * @notice Sets the period to be used for the TWAP calculation
   * @dev Will revert it is lower than the minimum period or greater than maximum period.
   *      Can only be called by users with the admin role
   *      WARNING: increasing the period could cause big problems, because Uniswap V3 pools might not support a TWAP so old
   * @param newPeriod The new period
   */
  function setPeriod(uint32 newPeriod) external;

  /**
   * @notice Sets the cardinality per minute to be used when increasing observation cardinality at the moment of adding support for pairs
   * @dev Will revert if the given cardinality is zero
   *      Can only be called by users with the admin role
   *      WARNING: increasing the cardinality per minute will make adding support to a pair significantly costly
   * @param cardinalityPerMinute The new cardinality per minute
   */
  function setCardinalityPerMinute(uint8 cardinalityPerMinute) external;

  /**
   * @notice Sets the gas cost per cardinality
   * @dev Will revert if the given gas cost is zero
   *      Can only be called by users with the admin role
   * @param gasPerCardinality The gas cost to set
   */
  function setGasPerCardinality(uint104 gasPerCardinality) external;

  /**
   * @notice Sets the gas cost to support a new pool
   * @dev Will revert if the given gas cost is zero
   *      Can only be called by users with the admin role
   * @param gasCostToSupportPool The gas cost to set
   */
  function setGasCostToSupportPool(uint112 gasCostToSupportPool) external;

  /**
   * @notice Sets the denylist status for a set of pairs
   * @dev Will revert if amount of pairs does not match the amount of bools
   *      Can only be called by users with the admin role
   * @param pairs The pairs to update
   * @param denylisted Whether they will be denylisted or not
   */
  function setDenylisted(Pair[] calldata pairs, bool[] calldata denylisted) external;
}