// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./basket/IBasketReader.sol";
import "./basket/IBasketGovernedActions.sol";

/**
 * @title The interface for a Float Protocol Asset Basket
 * @notice A Basket stores value used to stabilise price and assess the
 * the movement of the underlying assets we're trying to track.
 * @dev The Basket interface is broken up into many smaller pieces to allow only
 * relevant parts to be imported
 */
interface IBasket is IBasketReader, IBasketGovernedActions {

}