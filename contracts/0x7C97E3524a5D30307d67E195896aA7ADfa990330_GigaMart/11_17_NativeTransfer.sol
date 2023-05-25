// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// Emitted in the event that transfer of Ether fails.
error TransferFailed ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Native Ether Transfer Library
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for safely conducting Ether transfers and verifying success.

	@custom:date December 4th, 2022.
*/
library NativeTransfer {

	/**
		A helper function for wrapping a low-level Ether transfer call with modern 
		error reversion.

		@param _to The address to send Ether to.
		@param _value The value of Ether to send to `_to`.

		@custom:throws TransferFailed if the transfer of Ether fails.
	*/
	function transferEth (
		address _to,
		uint _value
	) internal {
		(bool success, ) = _to.call{ value: _value }("");
		if (!success) {
			revert TransferFailed();
		}
	}
}