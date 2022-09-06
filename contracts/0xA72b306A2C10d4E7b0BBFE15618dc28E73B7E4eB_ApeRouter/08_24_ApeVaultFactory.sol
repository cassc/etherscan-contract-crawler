// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "ApeVault.sol";
import "VaultProxy.sol";

contract ApeVaultFactory {
	mapping(address => bool) public vaultRegistry;

	address public yearnRegistry;
	address public apeRegistry;
	address public beacon;

	event VaultCreated(address vault);

	constructor(address _reg, address _apeReg, address _beacon) {
		apeRegistry = _apeReg;
		yearnRegistry = _reg;
		beacon = _beacon;
	}

	function createCoVault(address _token, address _simpleToken) external {
		bytes memory data = abi.encodeWithSignature("init(address,address,address,address,address)", apeRegistry, _token, yearnRegistry, _simpleToken, msg.sender);
		VaultProxy proxy = new VaultProxy(beacon, msg.sender, data);
		vaultRegistry[address(proxy)] = true;
		emit VaultCreated(address(proxy));
	}
}