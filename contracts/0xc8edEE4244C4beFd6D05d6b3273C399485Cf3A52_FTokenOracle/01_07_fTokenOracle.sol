/**SPDX-License-Identifier: MIT

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "contracts/lending/fTokenOracle/IFTokenOracle.sol";
import "contracts/lending/chainlink/AggregatorV3Interface.sol";
import "contracts/cash/external/openzeppelin/contracts/access/Ownable2Step.sol";

contract FTokenOracle is IFTokenOracle, Ownable2Step {
  /// @notice fToken price given by this Oracle
  IFToken public immutable fToken;
  /// @notice Chainlink price feed
  AggregatorV3Interface public immutable priceFeed;
  /// @notice Description of oracle in `fToken/Underlying Token Symbol` format
  string public override description;
  /// @notice Max delay when getting non-stale price
  uint256 public maxOracleTimeDelay;
  /// @notice Decimals of price returned by `getPrice ` and `getLatestPrice`
  uint8 public constant override decimals = 18;
  /// @notice Scale factor that the fToken exchange rate is scaled by from its
  /// underlying. Eg Initial exhcange rate for an 18 decimal underlying token
  /// is 18 + 8 = 26 decimals
  uint8 public constant FTOKEN_EXCHANGE_RATE_SCALE_FACTOR = 8;
  /// @notice Factor to scale by to return price in `decimals` of precision
  uint256 public immutable scaleFactor;

  constructor(
    address _fToken,
    address _priceFeed,
    string memory _description,
    uint256 _maxOracleTimeDelay
  ) {
    require(IFToken(_fToken).isCToken());

    fToken = IFToken(_fToken);
    priceFeed = AggregatorV3Interface(_priceFeed);
    description = _description;
    maxOracleTimeDelay = _maxOracleTimeDelay;

    // Set Scale Factor
    // The smallest number of decimals for an fTokenExchangeRate is 14.
    // The smallest number of decimals for a Chainlink price feed is 8 (USD).
    // Thus, we will always be scaling DOWN to 18 decimals.
    uint8 priceFeedDecimals = priceFeed.decimals();
    if (priceFeedDecimals < 8) {
      revert UnsupportedPriceFeed();
    }
    address fTokenUnderlying = fToken.underlying();
    uint8 fTokenUnderlyingDecimals = IERC20Like(fTokenUnderlying).decimals();
    if (fTokenUnderlying == address(0) || fTokenUnderlyingDecimals == 0) {
      revert InvalidFToken();
    }
    scaleFactor =
      10 **
        (priceFeedDecimals -
          FTOKEN_EXCHANGE_RATE_SCALE_FACTOR +
          fTokenUnderlyingDecimals);
  }

  /**
   * @notice Get a non-stale price of fToken denominated in asset specified by
   *         underlyingpriceFeed
   *
   * @dev Reverts when price <= 0 or when price is stale
   */
  function getLatestPrice() external override returns (uint256) {
    // Get underlying price and check for staleness and validity
    (
      uint80 roundId,
      int256 answer,
      ,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    if (
      answer < 0 ||
      roundId != answeredInRound ||
      roundId == 0 ||
      updatedAt == 0 ||
      updatedAt > block.timestamp
    ) {
      revert CorruptedChainlinkResponse();
    }

    if (answer == 0) {
      revert InvalidPrice();
    }

    if (updatedAt < block.timestamp - maxOracleTimeDelay) {
      revert StalePrice();
    }

    // Get fToken exchange Rate
    uint256 exchangeRate = fToken.exchangeRateCurrent();

    // Return fToken price denominated in underlying of price feed
    return _scale(uint256(answer), exchangeRate);
  }

  /**
   * @notice Get the price of fToken denominated in asset specified by
   *         underlyingpriceFeed
   *
   * @dev Function does not check for Chainlin oracle staleness. Use
   *      `getLatestPrice` for a non-stale price
   * @dev Reverts when price <= 0
   */
  function getPrice() external override returns (uint256) {
    // Get underlying price and check for validity
    (, int256 answer, , , ) = priceFeed.latestRoundData();

    if (answer <= 0) {
      revert InvalidPrice();
    }

    // Get fToken ExchangeRate
    uint256 exchangeRate = fToken.exchangeRateCurrent();

    // Return fToken price denominated in underlying of price feed
    return _scale(uint256(answer), exchangeRate);
  }

  /**
   * @notice Return the scaled price of fToken in 18 decimal units of
   *         priceFeed
   *
   * @param price Price of fTokenUnderlying denominated in priceFeed token
   * @param fTokenExchangeRate Exchange Rate of fToken
   */
  function _scale(
    uint256 price,
    uint256 fTokenExchangeRate
  ) private view returns (uint256) {
    return (price * fTokenExchangeRate) / scaleFactor;
  }

  /**
   * @notice Set time delay for oracle price feed
   *
   * @param newMaxOracleTimeDelay New max oracle time delay
   */
  function setMaxOracleTimeDelay(
    uint256 newMaxOracleTimeDelay
  ) external override onlyOwner {
    uint256 oldMaxOracleTimeDelay = maxOracleTimeDelay;
    maxOracleTimeDelay = newMaxOracleTimeDelay;
    emit MaxOracleTimeDelaySet(oldMaxOracleTimeDelay, newMaxOracleTimeDelay);
  }
}