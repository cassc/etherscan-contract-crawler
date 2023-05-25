// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	PermitControl
} from "../../access/PermitControl.sol";

import {
	_getProtocolFee,
	_setProtocolFee
} from "./Storage.sol";

/// Thrown if attempting to set the protocol fee to zero.
error ProtocolFeeRecipientCannotBeZero();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Protocol Fee Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing platform fee management capabilities to GigaMart.
*/
contract ProtocolFeeManager is PermitControl {

	/**
		The public identifier for the right to update the fee configuration.
		_FEE_CONFIG = keccak256("FEE_CONFIG");
	*/
	bytes32 private constant _FEE_CONFIG = 
		0x04c68c9fff15bf997e5ceb309a37aa8077e41018445f90182d108811f0c988e3;

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
			uint256 newProtocolFee =
				(uint256(uint160(_protocolFeeRecipient)) << 96) +
				uint256(_protocolFeePercent);
			_setProtocolFee(newProtocolFee);
		}
	}

	/**
		Returns current protocol fee config.
	*/
	function currentProtocolFee() public view returns (address, uint256) {
		uint256 fee = _getProtocolFee();
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
	) external hasValidPermit(_UNIVERSAL, _FEE_CONFIG) {
		if (_newProtocolFeeRecipient == address(0)) {
			revert ProtocolFeeRecipientCannotBeZero();
		}

		// Update the protocol fee.
		uint256 oldProtocolFee = _getProtocolFee();
		unchecked {
			uint256 newprotocolFee =
				(uint256(uint160(_newProtocolFeeRecipient)) << 96) +
				uint256(_newProtocolFeePercent);
			_setProtocolFee(newprotocolFee);
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