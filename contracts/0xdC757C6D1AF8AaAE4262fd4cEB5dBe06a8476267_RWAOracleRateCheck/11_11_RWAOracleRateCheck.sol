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
import "contracts/cash/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract RWAOracleRateCheck is IRWAOracle, AccessControlEnumerable {
  // Price of RWA token (OUSG, OSTB, OHYG, etc.)
  int256 public rwaPrice;

  // Timestamp in which the RWA token price was last set
  uint256 public priceTimestamp;

  // Minimum time between price updates
  uint256 public constant MIN_PRICE_UPDATE_WINDOW = 23 hours;

  // Helper constant that allows us to specify basis points in calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // 1%, for example, if RWA price is 100 on day 1, it can't be more than
  // 101 or less than 99 on day 2
  uint256 public constant MAX_CHANGE_DIFF_BPS = 100;

  // Max uint256
  uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

  // Role that can set RWA price
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

  /**
   * @notice Constructor
   *
   * @param admin The address of the admin
   * @param setter The address of the setter
   * @param initialprice The initial price of RWA
   */
  constructor(address admin, address setter, int256 initialprice) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(SETTER_ROLE, setter);

    if (initialprice <= 0) {
      revert InvalidPrice();
    }

    rwaPrice = initialprice;
    priceTimestamp = block.timestamp;

    emit RWAPriceSet(0, initialprice, block.timestamp);
  }

  /**
   * @notice Retrieve the last set RWA price data
   *
   * @dev `price` is in 18 decimals, `timestamp` is unix seconds since epoch
   */
  function getPriceData() external view override returns (uint256, uint256) {
    return (uint256(rwaPrice), priceTimestamp);
  }

  /**
   * @notice Set the RWA price
   *
   * @param newPrice The new RWA price
   *
   * @dev `MAX_CHANGE_DIFF_BPS` can be a positive or negative percent deviation
   */
  function setPrice(int256 newPrice) external onlyRole(SETTER_ROLE) {
    if (newPrice <= 0) {
      revert InvalidPrice();
    }
    if (block.timestamp - priceTimestamp < MIN_PRICE_UPDATE_WINDOW) {
      revert PriceUpdateWindowViolation();
    }
    if (_getPriceChangeBps(rwaPrice, newPrice) > MAX_CHANGE_DIFF_BPS) {
      revert DeltaDifferenceConstraintViolation();
    }

    // Set new price
    int256 oldPrice = rwaPrice;
    rwaPrice = newPrice;
    priceTimestamp = block.timestamp;

    emit RWAPriceSet(oldPrice, newPrice, block.timestamp);
  }

  /**
   * @notice Compute the price change in basis point
   *
   * @param previousPrice Previous price
   * @param newPrice      New price
   *
   * @dev The price change can be negative.
   */
  function _getPriceChangeBps(
    int256 previousPrice,
    int256 newPrice
  ) private pure returns (uint256) {
    uint256 change = newPrice > previousPrice
      ? uint256(newPrice - previousPrice)
      : uint256(previousPrice - newPrice);
    uint256 changeBps = mulDivUp(
      change,
      BPS_DENOMINATOR,
      uint256(previousPrice)
    );
    return changeBps;
  }

  /**
   * @notice MulDivUp function forked from solmate's implementation
   *
   * @dev Forked from solmate's V6 release
   */
  function mulDivUp(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
      if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
        revert(0, 0)
      }

      // If x * y modulo the denominator is strictly greater than 0,
      // 1 is added to round up the division of x * y by the denominator.
      z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
    }
  }

  /*//////////////////////////////////////////////////////////////
                          Events & Errors
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the RWA price is set
   *
   * @param oldPrice The old RWA price
   * @param newPrice The new RWA price
   * @param timestamp The timestamp at which the price was set
   */
  event RWAPriceSet(int256 oldPrice, int256 newPrice, uint256 timestamp);

  // Errors
  error InvalidPrice();
  error PriceUpdateWindowViolation();
  error DeltaDifferenceConstraintViolation();
}