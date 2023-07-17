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

interface IPricer {
  /**
   * @notice Gets the latest price of the asset
   *
   * @return uint256 The latest price of the asset
   */
  function getLatestPrice() external view returns (uint256);

  /**
   * @notice Gets the price of the asset at a specific priceId
   *
   * @param priceId The priceId at which to get the price
   *
   * @return uint256 The price of the asset with the given priceId
   */
  function getPrice(uint256 priceId) external view returns (uint256);

  /**
   * @notice Adds a price to the pricer
   *
   * @param price     The price to add
   * @param timestamp The timestamp associated with the price
   *
   * @dev Updates the oracle price if price is the latest
   */
  function addPrice(uint256 price, uint256 timestamp) external;

  /**
   * @notice Updates a price in the pricer
   *
   * @param priceId The priceId to update
   * @param price   The price to set
   */
  function updatePrice(uint256 priceId, uint256 price) external;

  /**
   * @notice Updates a price in the pricer by pulling it from the oracle
   */
  function addLatestOraclePrice() external;
}