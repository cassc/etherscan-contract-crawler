/**SPDX-License-Identifier: BUSL-1.1

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

/// @notice Taken from contracts/lending/compound/PriceOracle.sol
interface PriceOracle {
  /**
   * @notice Get the underlying price of a fToken asset
   * @param fToken The fToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   */
  function getUnderlyingPrice(address fToken) external view returns (uint);
}

interface IOndoPriceOracle is PriceOracle {
  function setPrice(address fToken, uint256 price) external;

  function setFTokenToCToken(address fToken, address cToken) external;

  function setOracle(address newOracle) external;

  /**
   * @dev Event for when a fToken to cToken association is set
   *
   * @param fToken    fToken address
   * @param oldCToken Old cToken association
   * @param newCToken New cToken association
   */
  event FTokenToCTokenSet(
    address indexed fToken,
    address oldCToken,
    address newCToken
  );

  /**
   * @dev Event for when a fToken's underlying asset's price is set
   *
   * @param fToken   fToken address
   * @param oldPrice Old underlying asset's price
   * @param newPrice New underlying asset's price
   */
  event UnderlyingPriceSet(
    address indexed fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  /**
   * @dev Event for when the cToken oracle is set
   *
   * @param oldOracle Old cToken oracle
   * @param newOracle New cToken oracle
   */
  event CTokenOracleSet(address oldOracle, address newOracle);
}

interface IOndoPriceOracleV2 is IOndoPriceOracle {
  /// @notice Enum denoting where the price of an fToken is coming from
  enum OracleType {
    UNINITIALIZED,
    MANUAL,
    COMPOUND,
    CHAINLINK
  }

  function setPriceCap(address fToken, uint256 value) external;

  function setFTokenToChainlinkOracle(
    address fToken,
    address newChainlinkOracle,
    uint256 maxChainlinkOracleTimeDelay
  ) external;

  function setFTokenToOracleType(
    address fToken,
    OracleType oracleType
  ) external;

  /**
   * @dev Event for when a price cap is set on an fToken's underlying assset
   *
   * @param fToken      fToken address
   * @param oldPriceCap Old price cap
   * @param newPriceCap New price cap
   */
  event PriceCapSet(
    address indexed fToken,
    uint256 oldPriceCap,
    uint256 newPriceCap
  );

  /**
   * @dev Event for when chainlink Oracle is set
   *
   * @param fToken                      fToken address
   * @param oldOracle                   The old chainlink oracle
   * @param newOracle                   The new chainlink oracle
   * @param maxChainlinkOracleTimeDelay The max time delay for the chainlink oracle
   */
  event ChainlinkOracleSet(
    address indexed fToken,
    address oldOracle,
    address newOracle,
    uint256 maxChainlinkOracleTimeDelay
  );

  /**
   * @dev Event for when a fToken to chainlink oracle association is set
   *
   * @param fToken     fToken address
   * @param oracleType New oracle association
   */
  event FTokenToOracleTypeSet(address indexed fToken, OracleType oracleType);
}