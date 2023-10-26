// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../DAOStackInterfaces.sol";

/**
@title Simple name to address resolver
*/

contract NameService is Initializable, UUPSUpgradeable {
	mapping(bytes32 => address) public addresses;

	Controller public dao;
	event AddressChanged(string name ,address addr);
	function initialize(
		Controller _dao,
		bytes32[] memory _nameHashes,
		address[] memory _addresses
	) public virtual initializer {
		dao = _dao;
		for (uint256 i = 0; i < _nameHashes.length; i++) {
			addresses[_nameHashes[i]] = _addresses[i];
		}
		addresses[keccak256(bytes("CONTROLLER"))] = address(_dao);
		addresses[keccak256(bytes("AVATAR"))] = address(_dao.avatar());
	}

	function _authorizeUpgrade(address) internal override {
		_onlyAvatar();
	}

	function _onlyAvatar() internal view {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setAddress(string memory name, address addr) external {
		_onlyAvatar();
		addresses[keccak256(bytes(name))] = addr;
		emit AddressChanged(name, addr);
	}

	function setAddresses(bytes32[] calldata hash, address[] calldata addrs)
		external
	{
		_onlyAvatar();
		for (uint256 i = 0; i < hash.length; i++) {
			addresses[hash[i]] = addrs[i];
		}
	}

	function getAddress(string memory name) external view returns (address) {
		return addresses[keccak256(bytes(name))];
	}
}