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

import {IERC20Like} from "contracts/lending/HelperInterfaces.sol";

/// @notice Helper interface for standardizing common calls to
///         fTokens
interface IFToken {
  function isCToken() external returns (bool);

  function exchangeRateCurrent() external returns (uint256);

  function underlying() external view returns (address);
}

interface IFTokenOracle {
  function description() external returns (string memory);

  function decimals() external returns (uint8);

  function getLatestPrice() external returns (uint256);

  function getPrice() external returns (uint256);

  function setMaxOracleTimeDelay(uint256 newMaxOracleTimeDelay) external;

  /**
   * @dev Event for when oracle max time delay is set
   *
   * @param oldMaxOracleTimeDelay The old max time delay for the chainlink oracle
   * @param newMaxOracleTimeDelay The new max time delay for the chainlink oracle
   */
  event MaxOracleTimeDelaySet(
    uint256 oldMaxOracleTimeDelay,
    uint256 newMaxOracleTimeDelay
  );

  // Errors
  error UnsupportedPriceFeed();
  error CorruptedChainlinkResponse();
  error StalePrice();
  error InvalidPrice();
  error InvalidFToken();
}