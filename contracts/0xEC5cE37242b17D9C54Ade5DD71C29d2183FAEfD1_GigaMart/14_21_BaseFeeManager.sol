// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	PermitControl
} from "../../access/PermitControl.sol";

/// Thrown if attempting to set the protocol fee to zero.
error ProtocolFeeRecipientCannotBeZero();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Base Fee Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing platform fee management capabilities to GigaMart.

	@custom:date December 4th, 2022.
*/
abstract contract BaseFeeManager is PermitControl {

	/// The public identifier for the right to update the fee configuration.
	bytes32 public constant FEE_CONFIG = keccak256("FEE_CONFIG");

	/**
		In protocol fee configuration the recipient address takes the left 160 bits 
		and the fee percentage takes the right 96 bits.
	*/
	uint256 internal _protocolFee;

	/**
		Emmited when protocol fee config is altered.

		@param oldProtocolFeeRecipient The previous recipient address of protocol 
			fees.
		@param newProtocolFeeRecipient The new recipient address of protocol fees.
		@param oldProtocolFeePercent The previous amount of protocol fees.
		@param newProtocolFeePercent The new amount of protocol fees. 
	*/
	event ProtocolFeeChanged (
		address oldProtocolFeeRecipient,
		address newProtocolFeeRecipient,
		uint256 oldProtocolFeePercent,
		uint256 newProtocolFeePercent
	);

	/**
		Construct a new instance of the GigaMart fee manager.

		@param _protocolFeeRecipient The address that receives the protocol fee.
		@param _protocolFeePercent The percentage of the protocol fee in basis 
			points, i.e. 200 = 2%.
	*/
	constructor (
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) {
		unchecked {
			_protocolFee =
				(uint256(uint160(_protocolFeeRecipient)) << 96) +
				uint256(_protocolFeePercent);
		}
	}

	/**
		Returns current protocol fee config.
	*/
	function currentProtocolFee() public view returns (address, uint256) {
		uint256 fee = _protocolFee;
		return (address(uint160(fee >> 96)), uint256(uint96(fee)));
	}

	/**
		Changes the the fee details of the protocol.

		@param _newProtocolFeeRecipient The address of the new protocol fee 
			recipient.
		@param _newProtocolFeePercent The new amount of the protocol fees in basis 
			points, i.e. 200 = 2%.

		@custom:throws ProtocolFeeRecipientCannotBeZero if attempting to set the 
			recipient of the protocol fees to the zero address.
	*/
	function changeProtocolFees (
		address _newProtocolFeeRecipient,
		uint256 _newProtocolFeePercent
	) external hasValidPermit(UNIVERSAL, FEE_CONFIG) {
		if (_newProtocolFeeRecipient == address(0)) {
			revert ProtocolFeeRecipientCannotBeZero();
		}

		// Update the protocol fee.
		uint256 oldProtocolFee = _protocolFee;
		unchecked {
			_protocolFee =
				(uint256(uint160(_newProtocolFeeRecipient)) << 96) +
				uint256(_newProtocolFeePercent);
		}

		// Emit an event notifying about the update.
		emit ProtocolFeeChanged(
			address(uint160(oldProtocolFee >> 96)),
			_newProtocolFeeRecipient,
			uint256(uint96(oldProtocolFee)),
			_newProtocolFeePercent
		);
	}
}