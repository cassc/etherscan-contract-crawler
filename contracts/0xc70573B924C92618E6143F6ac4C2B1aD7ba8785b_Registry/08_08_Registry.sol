import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Registry is AccessControl, Ownable {
	event DeployRegistry();
	event Register(address indexed addressRegistered, bytes4[] interfaceIds, address registeredBy);
	event Unregister(address indexed addressUnregistered, bytes4[] interfaceIds, address unregisteredBy);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	// contract address => interface id => supported boolean
	mapping (address => mapping (bytes4 => bool)) private interfaces;

	constructor() Ownable() {
		emit DeployRegistry();
	}

	function addAdmin(address admin) public onlyOwner {
		_grantRole(ADMIN_ROLE, admin);
	}

	function removeAdmin(address admin) public onlyOwner {
		_revokeRole(ADMIN_ROLE, admin);
	}

	function register(address addressRegistered, bytes4[] calldata interfaceIds) public onlyRole(ADMIN_ROLE) {
		for (uint i = interfaceIds.length; i != 0;) {
			interfaces[addressRegistered][interfaceIds[i - 1]] = true;
			unchecked {
				--i;
			}
		}

		emit Register(addressRegistered, interfaceIds, msg.sender);
	}

	function unregister(address addressUnregistered, bytes4[] calldata interfaceIds) public onlyRole(ADMIN_ROLE) {
		for (uint i = interfaceIds.length; i != 0;) {
			interfaces[addressUnregistered][interfaceIds[i - 1]] = false;
			unchecked {
				--i;
			}
		}
		emit Unregister(addressUnregistered, interfaceIds, msg.sender);
	}

	function targetSupportsInterface(address target, bytes4 interfaceId) public view returns(bool) {
		return interfaces[target][interfaceId];
	}
}