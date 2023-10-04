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

import "contracts/rwaOracles/IRWAOracle.sol";
import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/ommf/ommf_token/ommf.sol";

/// @notice This contract is based on `RWAOracleRateCheck`, with minor updates
///         to call into the OMMF token
contract OMMFRebaseSetter is AccessControlEnumerable {
  // Timestamp in which the RWA underlying was last set
  uint256 public priceTimestamp;

  // Minimum time between price updates
  uint256 public constant MIN_PRICE_UPDATE_WINDOW = 6 hours;

  // Helper constant that allows us to specify basis points in calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // 0.5%, for example, if RWA price is 100 on day 1, it can't be more than
  // 100.5 or less than 99.5 on day 2
  uint256 public constant MAX_CHANGE_DIFF_BPS = 50;

  // 0.005%, for example, if RWA price is 100 on day 1, it can't be more than
  // 100.005 or less than 99.995 on day 2
  uint256 public constant OPS_MAX_CHANGE_DIFF_BPS = 3;

  // Max uint256
  uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

  // Role that can set RWA price
  bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

  // Ops role that can set the price
  bytes32 public constant OPS_SETTER_ROLE = keccak256("OPS_SETTER_ROLE");

  // OMMF token
  OMMF public immutable ommf;

  /**
   * @notice Constructor
   *
   * @param admin        The address of the admin
   * @param setter       The address of the setter
   * @param _ommf        The address of the OMMF token
   */
  constructor(address admin, address setter, address _ommf) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(SETTER_ROLE, setter);
    _grantRole(OPS_SETTER_ROLE, setter);

    ommf = OMMF(_ommf);

    priceTimestamp = block.timestamp;

    emit RWAUnderlyingSet(0, int256(ommf.depositedCash()), block.timestamp);
  }

  /**
   * @notice Set the RWA underlying value
   *
   * @param oldUnderlying The old RWA underlying value
   * @param newUnderlying The new RWA underlying value
   *
   * @dev `OPS_MAX_CHANGE_DIFF_BPS` can be a positive or negative percent deviation
   * @dev This function will fail when ommf underlying is initially 0
   * @dev This function will fail if `oldUnderlying` doesn't match
   *      `ommf.getTotalPooledCash()`
   */
  function setRWAUnderlyingOps(
    int256 oldUnderlying,
    int256 newUnderlying
  ) external onlyRole(OPS_SETTER_ROLE) {
    if (
      _getPriceChangeBps(oldUnderlying, newUnderlying) > OPS_MAX_CHANGE_DIFF_BPS
    ) {
      revert DeltaDifferenceConstraintViolation();
    }
    _setRWAUnderlying(oldUnderlying, newUnderlying);
  }

  /**
   * @notice Set the RWA underlying value
   *
   * @param oldUnderlying The old RWA underlying value
   * @param newUnderlying The new RWA underlying value
   *
   * @dev `MAX_CHANGE_DIFF_BPS` can be a positive or negative percent deviation
   * @dev This function will fail when ommf underlying is initially 0
   * @dev This function will fail if `oldUnderlying` doesn't match
   *      `ommf.getTotalPooledCash()`
   */
  function setRWAUnderlying(
    int256 oldUnderlying,
    int256 newUnderlying
  ) external onlyRole(SETTER_ROLE) {
    _setRWAUnderlying(oldUnderlying, newUnderlying);
  }

  function _setRWAUnderlying(
    int256 oldUnderlying,
    int256 newUnderlying
  ) internal {
    if (newUnderlying <= 0) {
      revert InvalidPrice();
    }
    if (block.timestamp - priceTimestamp < MIN_PRICE_UPDATE_WINDOW) {
      revert PriceUpdateWindowViolation();
    }

    if (oldUnderlying != int256(ommf.depositedCash())) {
      revert OldUnderlyingMismatch();
    }
    // Constrain the size of the rebase
    if (
      _getPriceChangeBps(oldUnderlying, newUnderlying) > MAX_CHANGE_DIFF_BPS
    ) {
      revert DeltaDifferenceConstraintViolation();
    }

    priceTimestamp = block.timestamp;

    // Set price in OMMF token
    ommf.handleOracleReport(uint256(newUnderlying));

    emit RWAUnderlyingSet(oldUnderlying, newUnderlying, block.timestamp);
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
   * @notice Emitted when the RWA Underlying is set
   *
   * @param oldRwaUnderlying The old RWA underlying
   * @param newRwaUnderlying The new RWA underlying
   * @param timestamp        The timestamp at which the underlying was set
   */
  event RWAUnderlyingSet(
    int256 oldRwaUnderlying,
    int256 newRwaUnderlying,
    uint256 timestamp
  );

  // Errors
  error InvalidPrice();
  error PriceUpdateWindowViolation();
  error DeltaDifferenceConstraintViolation();
  error OldUnderlyingMismatch();
}