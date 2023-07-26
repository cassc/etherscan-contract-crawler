// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IEtherealWorlds {
	function ownerOf(uint256 id) external view returns (address user);
}

contract EtherealFragmentsStorage is ERC20("Ethereal Fragments", "FRAGZ"), Ownable {
	event FragzBurnt(address indexed user, uint256 burnt, uint256 indexed concerning, string extraData);
	event FragzClaimed(address indexed user, uint256[] worlds, uint256 amount);

	uint256 constant public BASE_RATE = 2 ether; // Not actually ether
	uint256 constant public DISTRIBUTION_END = 1643533200 + 157784760; // Start time + duration

    mapping(uint256 => uint256) public lastUpdate;
	
    IEtherealWorlds public worldsContract;
	IEtherealWorlds public specialWorldsContract;

    address _mainContract;
}