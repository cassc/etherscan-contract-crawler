// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGrade24 {

	event registered(address indexed child, address indexed parent);
	event updateP(address indexed from, address indexed to, uint256 indexed round, int256 pBalance, uint8 pType);
	event rewarded(address indexed to, uint256 indexed round, uint256 grade, uint256 normalReward, uint256 tzedakahReward);
	
    function updateBreedP(address from, int256 qty ) external;
	function updateTicketP(address from, int256 qty ) external;
	function registerExt(address from, address myParent) external;
	function isRegistered(address from) external view returns (bool);
}