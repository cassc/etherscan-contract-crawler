// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/presets/ERC20PresetFixedSupply.sol";
import "./ERC20WithPermit.sol";

contract SportsIcon is ERC20PresetFixedSupply, ERC20WithPermit {
	constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20PresetFixedSupply(name, symbol, initialSupply, owner) {
	}
}