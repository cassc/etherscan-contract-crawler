// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MasterchefMasterToken is ERC20, Ownable {
	constructor() ERC20("Masterchef Master Token", "MMT") {
		_mint(msg.sender, 1e18);
	}
}