// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A contract for letting people check the Chain.
	@author Tim Clancy <tim-clancy.eth>
	@custom:version 1.0

	The Chain is a realm of truths and half-truths, but it never lies. It is 
	decentralized, after all. Check the Chain today and see what mysteries may be 
	uncovered.

	@custom:date April 25th, 2023.
*/
contract Chain {

	/// Store a mapping of information on the Chain.
	mapping ( string => mapping ( uint256 => string )) public data;

	/**
		This event is emitted when something is set on the Chain.

		@param setter The address of the caller who set the value.
		@param item The item being updated.
		@param index The index of the item being updated.
		@param value The value put onto the Chain.
	*/
	event Set (
		address indexed setter,
		string item,
		uint256 index,
		string value
	);

	/**
		Allow a caller to set a particular piece of data on the Chain.

		@param _item The item being updated.
		@param _index The index of the item being updated.
		@param _value The value put onto the Chain.
	*/
	function set (
		string calldata _item,
		uint256 _index,
		string calldata _value
	) external {
		data[_item][_index] = _value;

		// Emit an event.
		emit Set(msg.sender, _item, _index, _value);
	}
}