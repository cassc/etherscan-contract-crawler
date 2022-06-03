// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OrderTypes} from '../libs/OrderTypes.sol';

interface IComplication {
  function canExecMatchOrder(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) external view returns (bool, uint256);

  function canExecTakeOrder(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    external
    view
    returns (bool, uint256);

  function canExecOneToMany(OrderTypes.Order calldata makerOrder, OrderTypes.Order[] calldata takerOrders)
    external
    view
    returns (bool);

  function getProtocolFee() external view returns (uint256);
}