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

import "contracts/lending/rwaOracles/IRWAOracle.sol";

interface IRWAOracleExternalComparisonCheck is IRWAOracle {
  /// @notice Set the RWA price
  function setPrice(int256 newPrice) external;

  /// EVENTS ///
  /**
   * @dev Event for when the price is set nominally
   *
   * @param oldChainlinkPrice Old Chainlink price
   * @param oldRoundId        Chainlink round ID of old price
   * @param newChainlinkPrice New Chainlink price
   * @param newRoundId        Chainlink round ID of old price
   * @param oldRWAPrice       Old RWA price
   * @param newRWAPrice       New RWA price
   */
  event RWAExternalComparisonCheckPriceSet(
    int256 oldChainlinkPrice,
    uint80 indexed oldRoundId,
    int256 newChainlinkPrice,
    uint80 indexed newRoundId,
    int256 oldRWAPrice,
    int256 newRWAPrice
  );

  /**
   * @dev Event for when the Chainlink price is out of reasonable bounds is
   *      is ignored
   *
   * @param oldChainlinkPrice Old Chainlink price
   * @param oldRoundId        Chainlink round ID of old price
   * @param newChainlinkPrice New Chainlink price
   * @param newRoundId        Chainlink round ID of old price
   */
  event ChainlinkPriceIgnored(
    int256 oldChainlinkPrice,
    uint80 indexed oldRoundId,
    int256 newChainlinkPrice,
    uint80 indexed newRoundId
  );

  /// ERRORS ///
  error CorruptedChainlinkResponse();
  error ChainlinkOraclePriceStale();
  error DeltaDifferenceConstraintViolation();
  error AbsoluteDifferenceConstraintViolated();
  error PriceUpdateWindowViolation();
  error InvalidRWAPrice();
  error ChainlinkRoundNotUpdated();
  error InvalidAddress();
}