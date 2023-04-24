// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@mean-finance/transformers/solidity/interfaces/ITransformerRegistry.sol';
import './ITokenPriceOracle.sol';

/**
 * @title An implementation of `ITokenPriceOracle` that handles transformations between tokens
 * @notice This oracle takes the transformer registry, and will transform some dependent tokens into their underlying
 *         tokens before quoting. We do this because it's hard to quote `yield-bearing(USDC) => yield-bearing(ETH)`.
 *         But we can easily do something like `yield-bearing(USDC) => USDC => ETH => yield-bearing(ETH)`. So the
 *         idea is to use the transformer registry to transform between dependent and their underlying, and then
 *         quote the underlyings.
 */
interface ITransformerOracle is ITokenPriceOracle {
  /// @notice How a specific pair will be mapped to their underlying tokens
  struct PairSpecificMappingConfig {
    // Whether tokenA will be mapped to its underlying (tokenA < tokenB)
    bool mapTokenAToUnderlying;
    // Whether tokenB will be mapped to its underlying (tokenA < tokenB)
    bool mapTokenBToUnderlying;
    // Whether the config is set
    bool isSet;
  }

  /// @notice Pair-specifig mapping configuration to set
  struct PairSpecificMappingConfigToSet {
    // One of the pair's tokens
    address tokenA;
    // The other of the pair's tokens
    address tokenB;
    // Whether to map tokenA to its underlying
    bool mapTokenAToUnderlying;
    // Whether to map tokenB to its underlying
    bool mapTokenBToUnderlying;
  }

  /// @notice A pair of tokens
  struct Pair {
    // One of the pair's tokens
    address tokenA;
    // The other of the pair's tokens
    address tokenB;
  }

  /// @notice Thrown when a parameter is the zero address
  error ZeroAddress();

  /**
   * @notice Emitted when new dependents are set to avoid mapping to their underlying counterparts
   * @param dependents The tokens that will avoid mapping
   */
  event DependentsWillAvoidMappingToUnderlying(address[] dependents);

  /**
   * @notice Emitted when dependents are set to map to their underlying counterparts
   * @param dependents The tokens that will map to underlying
   */
  event DependentsWillMapToUnderlying(address[] dependents);

  /**
   * @notice Emitted when dependents pair-specific mapping config is set
   * @param config The config that was set
   */
  event PairSpecificConfigSet(PairSpecificMappingConfigToSet[] config);

  /**
   * @notice Emitted when dependents pair-specific mapping config is cleared
   * @param pairs The pairs that had their config cleared
   */
  event PairSpecificConfigCleared(Pair[] pairs);

  /**
   * @notice Returns the address of the transformer registry
   * @dev Cannot be modified
   * @return The address of the transformer registry
   */
  function REGISTRY() external view returns (ITransformerRegistry);

  /**
   * @notice Returns the address of the underlying oracle
   * @dev Cannot be modified
   * @return The address of the underlying oracle
   */
  function UNDERLYING_ORACLE() external view returns (ITokenPriceOracle);

  /**
   * @notice Returns whether the given dependent will avoid mapping to their underlying counterparts
   * @param dependent The dependent token to check
   * @return Whether the given dependent will avoid mapping to their underlying counterparts
   */
  function willAvoidMappingToUnderlying(address dependent) external view returns (bool);

  /**
   * @notice Takes a pair of tokens, and maps them to their underlying counterparts if they exist, and if they
   *         haven't been configured to avoid mapping. Pair-specific config will be prioritized, but if it isn't
   *         set, then global config will be used.
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return mappedTokenA tokenA's underlying token, if exists and isn't configured to avoid mapping.
   *                      Otherwise tokenA
   * @return mappedTokenB tokenB's underlying token, if exists and isn't configured to avoid mapping.
   *                      Otherwise tokenB
   */
  function getMappingForPair(address tokenA, address tokenB) external view returns (address mappedTokenA, address mappedTokenB);

  /**
   * @notice Very similar to `getMappingForPair`, but recursive. Since an underlying could have an underlying, we might need to map
   *         the given pair recursively
   */
  function getRecursiveMappingForPair(address tokenA, address tokenB) external view returns (address mappedTokenA, address mappedTokenB);

  /**
   * @notice Returns any pair-specific mapping configuration for the given tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   */
  function pairSpecificMappingConfig(address tokenA, address tokenB) external view returns (PairSpecificMappingConfig memory);

  /**
   * @notice Determines that the given dependents will avoid mapping to their underlying counterparts, and
   *         instead perform quotes with their own addreses. This comes in handy with situations such as
   *         ETH/WETH, where some oracles use WETH instead of ETH
   * @param dependents The dependent tokens that should avoid mapping to underlying
   */
  function avoidMappingToUnderlying(address[] calldata dependents) external;

  /**
   * @notice Determines that the given dependents go back to mapping to their underlying counterparts (the
   *         default behaviour)
   * @param dependents The dependent tokens that should go back to mapping to underlying
   */
  function shouldMapToUnderlying(address[] calldata dependents) external;

  /**
   * @notice Determines how the given pairs should be mapped to their underlying tokens
   * @param config A list of pairs to configure
   */
  function setPairSpecificMappingConfig(PairSpecificMappingConfigToSet[] calldata config) external;

  /**
   * @notice Cleares any pair-specific mapping config for the given list of pairs
   * @param pairs The pairs that will have their config cleared
   */
  function clearPairSpecificMappingConfig(Pair[] calldata pairs) external;
}