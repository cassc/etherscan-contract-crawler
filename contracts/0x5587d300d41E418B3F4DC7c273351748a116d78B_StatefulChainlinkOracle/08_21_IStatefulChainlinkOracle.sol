// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol';
import './ITokenPriceOracle.sol';

/**
 * @title An implementation of IPriceOracle that uses Chainlink feeds
 * @notice This oracle will attempt to use all available feeds to determine prices between pairs
 */
interface IStatefulChainlinkOracle is ITokenPriceOracle {
  /// @notice The plan that will be used to calculate quotes for a given pair
  enum PricingPlan {
    // There is no plan calculated
    NONE,
    // Will use the ETH/USD feed
    ETH_USD_PAIR,
    // Will use a token/USD feed
    TOKEN_USD_PAIR,
    // Will use a token/ETH feed
    TOKEN_ETH_PAIR,
    // Will use tokenIn/USD and tokenOut/USD feeds
    TOKEN_TO_USD_TO_TOKEN_PAIR,
    // Will use tokenIn/ETH and tokenOut/ETH feeds
    TOKEN_TO_ETH_TO_TOKEN_PAIR,
    // Will use tokenA/USD, tokenB/ETH and ETH/USD feeds
    TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B,
    // Will use tokenA/ETH, tokenB/USD and ETH/USD feeds
    TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B,
    // Used then tokenA is the same as tokenB
    SAME_TOKENS
  }

  /**
   * @notice Emitted when the oracle updated the pricing plan for a pair
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param plan The new plan
   */
  event UpdatedPlanForPair(address tokenA, address tokenB, PricingPlan plan);

  /**
   * @notice Emitted when new tokens are considered USD
   * @param tokens The new tokens
   */
  event TokensConsideredUSD(address[] tokens);

  /**
   * @notice Emitted when tokens should no longer be considered USD
   * @param tokens The tokens to no longer consider USD
   */
  event TokensNoLongerConsideredUSD(address[] tokens);

  /**
   * @notice Emitted when new mappings are added
   * @param tokens The tokens
   * @param mappings Their new mappings
   */
  event MappingsAdded(address[] tokens, address[] mappings);

  /// @notice Thrown when the price is non-positive
  error InvalidPrice();

  /// @notice Thrown when the last price update was too long ago
  error LastUpdateIsTooOld();

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the input for adding mappings in invalid
  error InvalidMappingsInput();

  /**
   * @notice Returns how old the last price update can be before the oracle reverts by considering it too old
   * @dev Cannot be modified
   * @return How old the last price update can be in seconds
   */
  function MAX_DELAY() external view returns (uint32);

  /**
   * @notice Returns the Chainlink feed registry
   * @return The Chainlink registry
   */
  function registry() external view returns (FeedRegistryInterface);

  /**
   * @notice Returns the pricing plan that will be used when quoting the given pair
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @return The pricing plan that will be used
   */
  function planForPair(address tokenA, address tokenB) external view returns (PricingPlan);

  /**
   * @notice Returns the mapping of the given token, if it exists. If it doesn't, then the original token is returned
   * @return If it exists, the mapping is returned. Otherwise, the original token is returned
   */
  function mappedToken(address token) external view returns (address);

  /**
   * @notice Adds new token mappings
   * @param addresses The addresses of the tokens
   * @param mappings The addresses of their mappings
   */
  function addMappings(address[] calldata addresses, address[] calldata mappings) external;
}