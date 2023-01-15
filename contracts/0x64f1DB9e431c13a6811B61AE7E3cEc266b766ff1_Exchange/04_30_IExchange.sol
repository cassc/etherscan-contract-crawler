// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

import "contracts/sbinft/market/v1/library/OrderDomain.sol";

/**
 * @title SBINFT Exchange protocol
 */
interface IExchange is IERC165Upgradeable {
  // Emits whenever there is a exchange/sale
  event Sale(uint256 indexed nonce);
  // Emits whenever an order gets cancelled
  event OrderCancelled(uint256 indexed nonce);

  /**
   * @dev Try to exchange asset in process of Sale
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _salerSign saler signature
   * @param _buyOrder OrderDomain.BuyOrder
   * @param _buyerSign buyer signature
   * @param _platformSign platform signature
   */
  function exchange(
    OrderDomain.SaleOrder calldata _saleOrder,
    bytes calldata _salerSign,
    OrderDomain.BuyOrder calldata _buyOrder,
    bytes calldata _buyerSign,
    bytes calldata _platformSign
  ) external payable;

  /**
   * @dev Try to cancel Sale order
   *
   * @param _saleOrder OrderDomain.SaleOrder
   * @param _salerSign saler signature
   * @param _platformSign platform signature
   */
  function cancel(
    OrderDomain.SaleOrder calldata _saleOrder,
    bytes calldata _salerSign,
    bytes calldata _platformSign
  ) external;
}