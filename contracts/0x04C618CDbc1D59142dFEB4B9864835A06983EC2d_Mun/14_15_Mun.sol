// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC777.sol";
import "./AccessControl.sol";

contract Mun is ERC777, AccessControl {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	constructor() ERC777("Joseon Mun", "JSM", new address[](0)) {
		_grantRole(DEFAULT_ADMIN_ROLE, address(0x8EbF6F0Ec8e4E179652F445747c1F4426D8B0a8d));
		_grantRole(MINTER_ROLE, address(0x8EbF6F0Ec8e4E179652F445747c1F4426D8B0a8d));

		_mint(msg.sender, 2400000000000 * 10 ** decimals(), "", "");
	}

	function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
		_mint(to, amount, "", "");
	}
}
