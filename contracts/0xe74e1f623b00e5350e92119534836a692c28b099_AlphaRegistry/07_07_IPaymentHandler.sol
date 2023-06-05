// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	IAlphaRegistry
} from "./IAlphaRegistry.sol";

/// An error thrown if Ether transfer fails.
error TransferFailed ();

/// An error thrown if trying to resubscribe when subscription is still active.
error SubscriptionStillActive ();

/**
	An error thrown if a subscriber does not supply exactly the correct amount of 
	Ether to pay for a subscription.
*/
error SubscriptionPriceNotMatched ();

/// Thrown if attempting to buy an inactive subscription.
error SubscriptionDoesNotExist ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Payment Handler Interface
	@author Rostislav Khlebnikov <@catpic5buck>

	The interface for the `PaymentHandler` contract.

	@custom:version 1.0
	@custom:date April 7th, 2023.
*/
interface IPaymentHandler {

	/**
		Return the duration of each subscription.

		@return _ The subscription duration.
	*/
	function SUBSCRIPTION_DURATION () external view returns (uint256);

	/**
		Return the `AlphaRegistry` contract address.

		@return _ The address of the `AlphaRegistry`.
	*/
	function REGISTRY () external view returns (IAlphaRegistry);

	/**
		Checks if a particular subcription is recurrent.

		@param _alphaCaller The address of the alpha caller.
		@param _subscriber The address of the subscriber.

		@return _ Whether or not the subscription is recurrent.
	*/
	function isSubscriptionRecurrent (
		address _alphaCaller,
		address _subscriber
	) external view returns (bool);

	/**
		Update caller status of the subscription and transfers fees and payments.

		@param _alphaCaller Address of the alpha caller.

		@custom:throws SubscriptionStillActive.
		@custom:throws SubscriptionPriceNotMatched.
		@custom:throws TransferFailed.
	*/
	function subscribe (
		address _alphaCaller
	) external payable;
}