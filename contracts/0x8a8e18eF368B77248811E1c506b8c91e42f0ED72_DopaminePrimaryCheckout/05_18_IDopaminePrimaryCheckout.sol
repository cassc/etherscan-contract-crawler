// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IDopaminePrimaryCheckoutEventsAndErrors} from "./IDopaminePrimaryCheckoutEventsAndErrors.sol";
import {IOwnable} from "../utils/IOwnable.sol";
import {Bundle, Order} from "../../payments/DopaminePrimaryCheckoutStructs.sol";
import {IEIP712Signable} from "../utils/IEIP712Signable.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Primary Checkout Interface
interface IDopaminePrimaryCheckout is IOwnable, IEIP712Signable, IDopaminePrimaryCheckoutEventsAndErrors {

    /// @notice Derives an order hash for a set of bundle purchases.
    function getOrderHash(
        string memory id,
        address purchaser,
        Bundle[] calldata bundles
    ) external returns (bytes32);

    /// @notice Derives the bundle hash associated with a specific bundle.
    function getBundleHash(
        uint64 brand,
        uint64 collection,
        uint64 colorway,
        uint64 size,
        uint256 price
    ) external returns (bytes32);

    /// @notice Processes a Dopamine bundle order.
    function checkout(Order calldata order) external payable;

    /// @notice Withdraw `amount` in wei from the contract address.
    function withdraw(uint256 amount, address to) external;

    /// @notice Sets an approved order signer for the contract.
    function setSigner(address signer, bool setting) external;

}