// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	Ownable
} from "@openzeppelin/contracts/access/Ownable.sol";
import {
	Address
} from "@openzeppelin/contracts/utils/Address.sol";

error RightNotSpecified();
error CallerHasNoAccess();
error ManagedRightNotSpecified();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title An advanced permission-management contract.
	@author Tim Clancy <@_Enoch>

	This contract allows for a contract owner to delegate specific rights to
	external addresses. Additionally, these rights can be gated behind certain
	sets of circumstances and granted expiration times. This is useful for some
	more finely-grained access control in contracts.

	The owner of this contract is always a fully-permissioned super-administrator.

	@custom:date August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
	using Address for address;

	/// A special reserved constant for representing no rights.
	bytes32 internal constant _ZERO_RIGHT = hex"00000000000000000000000000000000";

	/// A special constant specifying the unique, universal-rights circumstance.
	bytes32 internal constant _UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

	/**
		A special constant specifying the unique manager right. This right allows an
		address to freely-manipulate the `managedRight` mapping.
	*/
	bytes32 internal constant _MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

	/**
		A mapping of per-address permissions to the circumstances, represented as
		an additional layer of generic bytes32 data, under which the addresses have
		various permits. A permit in this sense is represented by a per-circumstance
		mapping which couples some right, represented as a generic bytes32, to an
		expiration time wherein the right may no longer be exercised. An expiration
		time of 0 indicates that there is in fact no permit for the specified
		address to exercise the specified right under the specified circumstance.

		@dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
		max-integer circumstance. Perpetual rights may be given an expiry time of
		max-integer.
	*/
	mapping ( address => mapping( bytes32 => mapping( bytes32 => uint256 ))) 
		internal _permissions;

	/**
		An additional mapping of managed rights to manager rights. This mapping
		represents the administrator relationship that various rights have with one
		another. An address with a manager right may freely set permits for that
		manager right's managed rights. Each right may be managed by only one other
		right.
	*/
	mapping ( bytes32 => bytes32 ) internal _managerRights;

	/**
		An event emitted when an address has a permit updated. This event captures,
		through its various parameter combinations, the cases of granting a permit,
		updating the expiration time of a permit, or revoking a permit.

		@param updater The address which has updated the permit.
		@param updatee The address whose permit was updated.
		@param circumstance The circumstance wherein the permit was updated.
		@param role The role which was updated.
		@param expirationTime The time when the permit expires.
	*/
	event PermitUpdated (
		address indexed updater,
		address indexed updatee,
		bytes32 circumstance,
		bytes32 indexed role,
		uint256 expirationTime
	);

	/**
		An event emitted when a management relationship in `managerRight` is
		updated. This event captures adding and revoking management permissions via
		observing the update history of the `managerRight` value.

		@param manager The address of the manager performing this update.
		@param managedRight The right which had its manager updated.
		@param managerRight The new manager right which was updated to.
	*/
	event ManagementUpdated (
		address indexed manager,
		bytes32 indexed managedRight,
		bytes32 indexed managerRight
	);

	/**
		A modifier which allows only the super-administrative owner or addresses
		with a specified valid right to perform a call.

		@param _circumstance The circumstance under which to check for the validity
			of the specified `right`.
		@param _right The right to validate for the calling address. It must be
			non-expired and exist within the specified `_circumstance`.
	*/
	modifier hasValidPermit (
		bytes32 _circumstance,
		bytes32 _right
	) {
		if (
			msg.sender != owner() &&
				!_hasRight(msg.sender, _circumstance, _right)
		) {
			revert CallerHasNoAccess();
		}
		_;
	}

	/**
		Determine whether or not an address has some rights under the given
		circumstance,

		@param _address The address to check for the specified `_right`.
		@param _circumstance The circumstance to check the specified `_right` for.
		@param _right The right to check for validity.

		@return true or false, whether user has rights and time is valid.
	*/
	function _hasRight (
		address _address,
		bytes32 _circumstance,
		bytes32 _right
	) internal view returns (bool) {
		return _permissions[_address][_circumstance][_right] > block.timestamp;
	}
	/**
		Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
		specified `_managedRight`.

		@param _managedRight The right which is to have its manager set to
			`_managerRight`.
		@param _managerRight The right whose `UNIVERSAL` holders may manage
			`_managedRight`.
	*/

	function setManagerRight (
		bytes32 _managedRight,
		bytes32 _managerRight
	) external virtual hasValidPermit(_UNIVERSAL, _MANAGER) {
		if (_managedRight == _ZERO_RIGHT) {
			revert ManagedRightNotSpecified();
		}
		_managerRights[_managedRight] = _managerRight;
		emit ManagementUpdated(msg.sender, _managedRight, _managerRight);
	}

	/**
		Set the permit to a specific address under some circumstances. A permit may
		only be set by the super-administrative contract owner or an address holding
		some delegated management permit.

		@param _address The address to assign the specified `_right` to.
		@param _circumstance The circumstance in which the `_right` is valid.
		@param _right The specific right to assign.
		@param _expirationTime The time when the `_right` expires for the provided
			`_circumstance`.
	*/
	function setPermit (
		address _address,
		bytes32 _circumstance,
		bytes32 _right,
		uint256 _expirationTime
	) public virtual hasValidPermit(_UNIVERSAL, _managerRights[_right]) {
		if(_right == _ZERO_RIGHT) {
			revert RightNotSpecified();
		}
		_permissions[_address][_circumstance][_right] = _expirationTime;
		emit PermitUpdated(
			msg.sender,
			_address,
			_circumstance,
			_right,
			_expirationTime
		);
	}

	/**
		Determine whether or not an address has some rights under the given
		circumstance, and if they do have the right, until when.

		@param _address The address to check for the specified `_right`.
		@param _circumstance The circumstance to check the specified `_right` for.
		@param _right The right to check for validity.

		@return The timestamp in seconds when the `_right` expires. If the timestamp
			is zero, we can assume that the user never had the right.
	*/
	function hasRightUntil (
		address _address,
		bytes32 _circumstance,
		bytes32 _right
	) public view returns (uint256) {
		return _permissions[_address][_circumstance][_right];
	}
}