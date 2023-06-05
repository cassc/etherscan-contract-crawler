// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	IPaymentHandler
} from "./IPaymentHandler.sol";

/// Thrown if the `subscribe` function is called by account other than handler.
error CallerIsNotPaymentHandler ();

/// Thrown if attempting to set address(0) as a new fee recipient.
error ProtocolFeeRecipientCannotBeZero ();

/// Thrown if attempting to set subscription price higher than price ceiling.
error PriceHigherThanCeiling ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Alpha Registry Interface
	@author Rostislav Khlebnikov <@catpic5buck>

	An interface for the AlphaRegistry contract.

	@custom:version 1.0
	@custom:date April 7th, 2023.
*/
interface IAlphaRegistry {

	/**
		Emitted when caller updated their price.

		@param alphaCaller Address of the caller.
		@param oldPrice Old price value.
		@param newPrice New price value.
	*/
	event PriceUpdated(
		address indexed alphaCaller,
		uint256 oldPrice,
		uint256 newPrice
	);

	/**
		Emitted when someone sibscribes.

		@param subscriber Address of the subscriber.
		@param alphaCaller Address of the caller.
		@param start Timestamp, when subsription started.
		@param end Timestamp, when subscription ends.
	*/
	event Subscribed(
		address indexed subscriber,
		address  indexed alphaCaller,
		uint256 start,
		uint256 end
	);

	/**
		Emitted when Admin updates fees.

		@param oldRecipient Old recipient address.
		@param oldPercent Old fee percent.
		@param newRecipient New recipient address.
		@param newPercent New fee percent.
	*/
	event FeeUpdated(
		address oldRecipient,
		uint256 oldPercent,
		address newRecipient,
		uint256 newPercent
	);

	/**
		Emitted when Adming updates subscriptions price ceiling.

		@param oldPriceCeiling Previous price ceiling value.
		@param newPriceCeiling New price ceiling value.
	*/
	event PriceCelingUpdated(
		uint256 oldPriceCeiling,
		uint256 newPriceCeiling
	);

	/**
		Updates subscription price for the msg.sender.

		@param _newPrice New price value.

		@custom:emits PriceUpdated event.
	*/
	function updatePrice (uint256 _newPrice) external;

	/**
		Stores subscription info. Only PaymentHandler contract
		can call this function.

		@param _alphaCaller Address of the alpha caller.
		@param _subscriber Address of the subscriber.
		@param _end Timestamp when subscription ends.
		
		@custom:throws CallerIsNotPaymentHandler.
		@custom:emits Subscribed event.
	*/
	function subscribe(
		address _alphaCaller,
		address _subscriber,
		uint256 _end
	) external;

	/**
		Updates fee recipient address and fee percent.
		Only admin can call this function.

		@param _newRecipient New fee recipient address.
		@param _newPercent New fee percent value.

		@custom:throws ProtocolFeeRecipientCannotBeZero.
		@custom:emits FeeUpdated event.
	*/
	function updateFee(
		address _newRecipient,
		uint256 _newPercent
	) external;

	/**
		Sets new PaymentHandler contract address.
		Only admin can call this function.

		@param _handler New PaymentHandler address.
	*/
	function setPaymentHandler (
		IPaymentHandler _handler
	) external;

	/**
		Updates subscriptions price ceiling. Only Admin can call this function.

		@param _newPriceCeiling New subscriptions price ceiling value;

		@custom:emits PriceCeilingUpdated.
	*/
	function updatePriceCeiling (
		uint256 _newPriceCeiling
	) external;

	/**
		Returns current fee recipient and fee percent.

		@return _  The fee recipient address.
		@return _ The fee percent.
	*/
	function currentFee() external view returns (address, uint256);

	/** 
		Returns current address of the PaymentHandler.

		@return _ PaymentHandler address.
	*/
	function handler() external view returns (IPaymentHandler);

	/**
		Returns current subscription price for the alpha caller.

		@param _caller Address of the alpha caller.

		@return _ Subscription price amount.
	*/
	function prices (
		address _caller
	) external view returns (uint256);

	/**
		Returns current subscription price ceiling.

		@return _ Subscription price ceiling.
	*/
	function priceCeiling () external view returns (uint256);

	/**
		Returns current subscription status for the alpha caller.

		@param _caller Address of the alpha caller.

		@return _ Subscription status flag.
	*/
	function created (
		address _caller
	) external view returns (bool);

	/**
		Returns a subscription's expiration timestamp.

		@param _subscriber Address of the subscriber.
		@param _alphaCaller Address of the alpha caller.

		@return _ A subscription's expiration timestamp.
	*/
	function timestamps (
		address _subscriber,
		address _alphaCaller
	) external view returns (uint256);

	/**
		Reads subscription information by its caller and subscriber
		addresses and returns:
			1. Subscription status - active/expired.
			2. Fee recipient address.
			3. Amount of fees to pay.
			4. Price of the subscription. 
		
		@param _alphaCaller Address of the alpha caller.
		@param _subscriber Address of the subscriber

		@return exists Subscription existence flag.
		@return active Flag of subscription being active.
		@return feeRecipient Fee recipient address.
		@return feeAmount Amount of fees to pay.
		@return price Subscription price.
	*/
	function subscriptionInfo (
		address _alphaCaller,
		address _subscriber
	) external view returns (
		bool exists,
		bool active,
		address feeRecipient,
		uint256 feeAmount,
		uint256 price
	);
}