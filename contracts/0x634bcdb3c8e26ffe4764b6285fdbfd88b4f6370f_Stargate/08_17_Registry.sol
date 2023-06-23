// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./Ownable.sol";

/// @title Registry contract for whole Apus ecosystem
/// @notice Holds addresses of all essential Apus contracts
contract Registry is Ownable {

	/// @notice Stores address under its id
	/// @dev Id is keccak256 hash of its string representation
	mapping (bytes32 => address) public addresses;

	/// @notice Emit when owner registers address
	/// @param id Keccak256 hash of its string id representation
	/// @param previousAddress Previous address value under given id
	/// @param newAddress New address under given id
	event AddressRegistered(bytes32 indexed id, address indexed previousAddress, address indexed newAddress);

	/* solhint-disable-next-line no-empty-blocks */
	constructor(address _initialOwner) Ownable(_initialOwner) {

	}


	/// @notice Getter for registered addresses
	/// @dev Returns zero address if address have not been registered before
	/// @param _id Registered address identifier
	function getAddress(bytes32 _id) external view returns(address) {
		return addresses[_id];
	}


	/// @notice Register address under given id
	/// @dev Only owner can register addresses
	/// @dev Emits `AddressRegistered` event
	/// @param _id Keccak256 hash of its string id representation
	/// @param _address Registering address
	function registerAddress(bytes32 _id, address _address) public onlyOwner {
		require(_address != address(0), "Can't register 0x0 address");
		address _previousAddress = addresses[_id];
		addresses[_id] = _address;
		emit AddressRegistered(_id, _previousAddress, _address);
	}

	/// @notice Register list of addresses under given list of ids
	/// @dev Only owner can register addresses
	/// @dev Emits `AddressRegistered` event for every address
	/// @param _ids List of keccak256 hashes of its string id representation
	/// @param _addresses List of registering addresses
	function batchRegisterAddresses(bytes32[] calldata _ids, address[] calldata _addresses) external onlyOwner {
		require(_ids.length == _addresses.length, "Lists do not match in length");

		for (uint256 i = 0; i < _ids.length; i++) {
			registerAddress(_ids[i], _addresses[i]);
		}
	}
}