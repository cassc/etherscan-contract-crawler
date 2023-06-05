// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	IAlphaRegistry,
	IPaymentHandler,
	PriceHigherThanCeiling,
	CallerIsNotPaymentHandler,
	ProtocolFeeRecipientCannotBeZero
} from "./interfaces/IAlphaRegistry.sol";
import {
	PermitControl
} from "./access/PermitControl.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Alpha Registry
	@author Rostislav Khlebnikov <@catpic5buck>

	The AlphaRegistry stores information about alpha board subscripions.

	@custom:version 1.0
	@custom:date April 7th, 2023.
*/
contract AlphaRegistry is IAlphaRegistry, PermitControl {

	/// The PermitControl access constant for managing fee configuration.
	bytes32 private constant _FEE_CONFIG = keccak256("FEE_CONFIG");

	/// The PermitControl access constant for setting the payment handler.
	bytes32 private constant _SET_HANDLER = keccak256("SET_HANDLER");

	/// The PermitControl access constant for setting subscription price ceilings.
	bytes32 private constant _PRICE_CEILING_MANAGER = keccak256(
		"PRICE_CEILING_MANAGER"
	);

	/// A divisor constant for calculating fees.
	uint256 private constant _PRECISION = 10_000;

	/// The price ceiling for current alpha board subscriptions.
	uint256 public priceCeiling;

	/**
		A storage slot which contains 160 bits of the fee recipient Address on the 
		left and 96 bits of the fee percent on the right.
	*/
	uint256 private _feeConfig;

	/// The adress of the Payment Handler contract.
	IPaymentHandler public handler;
	
	/// A mapping from each alpha caller to the price of their subscription.
	mapping ( address => uint256 ) public prices;

	/// A mappint from each alpha caller to the status of their subscription.
	mapping ( address => bool ) public created;

	/**
		A mapping of each subscriber and alpha caller to the subscription 
		expiration timestamp.
	*/
	mapping ( address => mapping ( address => uint256 )) public timestamps;

	/**
		Construct new instance of the AlphaRegistry with initial price ceiling and 
		fee details.

		@param _priceCeiling The initial subscription fee ceiling.
		@param _feeRecipient The fee recipient address.
		@param _feePercent The fee percent.
	*/
	constructor (
		uint256 _priceCeiling,
		address _feeRecipient,
		uint96 _feePercent
	) {
		priceCeiling = _priceCeiling;

		/*
			Pack 160 bits of feeRecipient address and 96 bits of feePercent
			and store in the _feeConfig slot.
		*/
		_feeConfig = (uint256(uint160(_feeRecipient)) << 96) +
			uint256(_feePercent);
	}

	/**
		Reads the expiration time of the subscription in question.
		Calls PaymentHandler to check if subscription is recurrent.

		@param _alphaCaller Alpha caller address.
		@param _subscriber Subscriber address.

		@return _ Flag of subscription being active.
	*/
	function _isSubscriptionActive (
		address _alphaCaller,
		address _subscriber
	) private view returns (bool) {

		// If subscription has expired, see if it is recurrent.
		if (block.timestamp > timestamps[_subscriber][_alphaCaller]) {
			return handler.isSubscriptionRecurrent(
				_alphaCaller,
				_subscriber
			);
		}
		return true;
	}

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
	) {

		// Read subscription status.
		exists = created[_alphaCaller];

		// Check if the subscription is active.
		active = _isSubscriptionActive(
			_alphaCaller,
			_subscriber
		);
		// Read the subscription price.
		price = prices[_alphaCaller];

		// Read fee recipient and percent.
		uint256 feePercent;
		(feeRecipient, feePercent) = currentFee();
		// Calculate amount of fees to pay.
		feeAmount = (price * feePercent) / _PRECISION;
	}

	/**
		Unpacks and returns the fee recipient address and fee percent.

		@return _ A tuple consisting of the (fee recipient address, fee percent).
	*/
	function currentFee () public view returns (address, uint256) {
		uint256 fee = _feeConfig;
		return (address(uint160(fee >> 96)), uint256(uint96(fee)));
	}

	/**
		Updates subscription price for the msg.sender.

		@param _newPrice New price value.

		@custom:throws PriceHigherThanCeiling.
		@custom:emits PriceUpdated event.
	*/
	function updatePrice (
		uint256 _newPrice
	) external {
		// Check new price against the ceiling.
		if (_newPrice > priceCeiling) {
			revert PriceHigherThanCeiling();
		}

		// Put old price on the stack.
		uint256 old = prices[msg.sender];

		// Update status of the subscription if needed.
		if (!created[msg.sender]) {
			created[msg.sender] = true;
		}
		
		// Update the caller's subscription price..
		prices[msg.sender] = _newPrice;

		emit PriceUpdated(msg.sender, old, _newPrice);
	}

	/**
		Stores subscription info. Only PaymentHandler contract
		can call this function.

		@param _alphaCaller Address of the alpha caller.
		@param _subscriber Address of the subscriber.
		@param _end Timestamp when subscription ends.
		
		@custom:throws CallerIsNotPaymentHandler.
		@custom:emits Subscribed event.
	*/
	function subscribe (
		address _alphaCaller,
		address _subscriber,
		uint256 _end
	) external {
		// Check if caller is the PaymentHandler contract.
		if (msg.sender != address(handler)) {
			revert CallerIsNotPaymentHandler();
		}

		// Update expiration time of the subscription.
		timestamps[_subscriber][_alphaCaller] = _end;
		
		emit Subscribed(
			_subscriber,
			_alphaCaller,
			block.timestamp,
			_end
		);
	}

	/**
		Sets new PaymentHandler contract address.
		Only admin can call this function.

		@param _handler New PaymentHandler address.
	*/
	function setPaymentHandler (
		IPaymentHandler _handler
	) external hasValidPermit(_UNIVERSAL, _SET_HANDLER) {
		handler = _handler;
	}

	/**
		Updates fee recipient address and fee percent.
		Only admin can call this function.

		@param _newRecipient New fee recipient address.
		@param _newPercent New fee percent value.

		@custom:throws ProtocolFeeRecipientCannotBeZero.
		@custom:emits FeeUpdated event.
	*/
	function updateFee (
		address _newRecipient,
		uint256 _newPercent
	) external hasValidPermit(_UNIVERSAL, _FEE_CONFIG) {
		if (_newRecipient == address(0)) {
			revert ProtocolFeeRecipientCannotBeZero();
		}

		// Update the fee.
		uint256 oldFeeConfig =_feeConfig;
		unchecked {
			_feeConfig =
				(uint256(uint160(_newRecipient)) << 96) +
				uint256(_newPercent);
		}

		// Emit an event notifying about the update.
		emit FeeUpdated(
			address(uint160(oldFeeConfig >> 96)),
			uint256(uint96(oldFeeConfig)),
			_newRecipient,
			_newPercent
		);
	}

	/**
		Updates subscriptions price ceiling. Only Admin can call this function.

		@param _newPriceCeiling New subscriptions price ceiling value;

		@custom:emits PriceCeilingUpdated.
	*/
	function updatePriceCeiling (
		uint256 _newPriceCeiling
	) external hasValidPermit(_UNIVERSAL, _PRICE_CEILING_MANAGER) {
		// Put old ceiling value on the stack.
		uint256 oldPriceCeiling =  priceCeiling;
		// Set new ceiling value.
		priceCeiling = _newPriceCeiling;

		emit PriceCelingUpdated(oldPriceCeiling, _newPriceCeiling);
	}
}