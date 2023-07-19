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

import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/interfaces/IPricer.sol";

contract USDYPricer is AccessControlEnumerable, IPricer {
  // Struct representing information for a given priceId
  struct PriceInfo {
    uint256 price;
    uint256 timestamp;
  }
  // Mapping from priceId to PriceInfo
  mapping(uint256 => PriceInfo) public prices;

  // Array of priceIds
  /// @dev These priceIds are not ordered by timestamp
  uint256[] public priceIds;

  // Pointer to last set priceId
  /// @dev This price may not be the latest price since prices can be added
  /// out of order in relation to their timestamp
  uint256 public currentPriceId;

  // Pointer to priceId associated with the latest price
  uint256 public latestPriceId;

  bytes32 public constant PRICE_UPDATE_ROLE = keccak256("PRICE_UPDATE_ROLE");

  constructor(address admin, address pricer) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(PRICE_UPDATE_ROLE, pricer);
  }

  /**
   * @notice Gets the latest price of the asset
   *
   * @return uint256 The latest price of the asset
   */
  function getLatestPrice() external view override returns (uint256) {
    return prices[latestPriceId].price;
  }

  /**
   * @notice Gets the latest price of the asset
   *
   * @return uint256 The price of the asset
   */
  function getPrice(uint256 priceId) external view override returns (uint256) {
    return prices[priceId].price;
  }

  /**
   * @notice Adds a price to the pricer
   *
   * @param price     The price to add
   * @param timestamp The timestamp associated with the price
   */
  function addPrice(
    uint256 price,
    uint256 timestamp
  ) external virtual override onlyRole(PRICE_UPDATE_ROLE) {
    if (price == 0) {
      revert InvalidPrice();
    }

    // Set price
    uint256 priceId = ++currentPriceId;
    prices[priceId] = PriceInfo(price, timestamp);
    priceIds.push(priceId);

    // Update latestPriceId
    if (timestamp > prices[latestPriceId].timestamp) {
      latestPriceId = priceId;
    }

    emit PriceAdded(priceId, price, timestamp);
  }

  /**
   * @notice Updates a price in the pricer
   *
   * @param priceId The priceId to update
   * @param price   The price to set
   */
  function updatePrice(
    uint256 priceId,
    uint256 price
  ) external override onlyRole(PRICE_UPDATE_ROLE) {
    if (price == 0) {
      revert InvalidPrice();
    }
    if (prices[priceId].price == 0) {
      revert PriceIdDoesNotExist();
    }

    PriceInfo memory oldPriceInfo = prices[priceId];
    prices[priceId] = PriceInfo(price, oldPriceInfo.timestamp);

    emit PriceUpdated(priceId, oldPriceInfo.price, price);
  }

  /*//////////////////////////////////////////////////////////////
                           Events & Errors
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a price is added
   *
   * @param priceId   The priceId associated with the price
   * @param price     The price that was added
   * @param timestamp The timestamp associated with the price
   */
  event PriceAdded(uint256 indexed priceId, uint256 price, uint256 timestamp);

  /**
   * @notice Emitted when a price is updated
   *
   * @param priceId  The priceId associated with the price to update
   * @param oldPrice The old price associated with the priceId
   * @param newPrice The price that was updated to
   */
  event PriceUpdated(
    uint256 indexed priceId,
    uint256 oldPrice,
    uint256 newPrice
  );

  // Errors
  error InvalidPrice();
  error PriceIdDoesNotExist();
}