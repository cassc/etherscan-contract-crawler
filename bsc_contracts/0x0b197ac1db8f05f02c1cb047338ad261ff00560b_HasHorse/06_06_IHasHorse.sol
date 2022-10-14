// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IHasHorse {

	struct Horse {
		string name;
		uint64 endurance;
		uint64 speed;
		uint64 stamina;
		uint64 force;
		uint64 temper;
		uint64 grassField;
		uint64 muddyField;
		uint128 adaptability1;
		uint128 adaptability2;
		bool isSuperHorse;
	}
	
	struct SuperHorse {
		uint8 ownBreed;
		uint16 rented;
	}
	
    function setHorse(uint256 tokenId, Horse memory _horse) external;
	function maintainSuperBreed(uint256 tokenId, bool ownBreed) external;
	function becomeSuperHorse(uint256 tokenId) external;
    function burnHorse(uint256 tokenId) external;
	function getHorse(uint256 tokenId) external view returns (Horse memory, SuperHorse memory) ;
	 
}