// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./IHasHorse.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract HasHorse is Initializable, OwnableUpgradeable, IHasHorse {

    mapping(uint256 => Horse) public horse; //token id => horse
	mapping(uint256 => SuperHorse) public superHorse; //token id => super horse

    address salesContract;

    modifier onlySalesContract() {
        require(
            msg.sender == salesContract,
            "Only callable from sales contract"
        );
        _;
    }

    function setSalesContract(address _salesContract) public onlyOwner {
        salesContract = _salesContract;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function getHorse(uint256 tokenId) external view returns (Horse memory, SuperHorse memory) {
        return (horse[tokenId], superHorse[tokenId]);
    }

    function setHorse(uint256 tokenId, Horse memory _horse)
        external
        onlySalesContract
    {
        Horse storage horseStorage = horse[tokenId];
        horseStorage.name = _horse.name;
        horseStorage.endurance = _horse.endurance;
        horseStorage.speed = _horse.speed;
        horseStorage.stamina = _horse.stamina;
        horseStorage.force = _horse.force;
        horseStorage.temper = _horse.temper;
        horseStorage.grassField = _horse.grassField;
        horseStorage.muddyField = _horse.muddyField;
        horseStorage.adaptability1 = _horse.adaptability1;
        horseStorage.adaptability2 = _horse.adaptability2;
        horseStorage.isSuperHorse = false;
    }

	function maintainSuperBreed(uint256 tokenId, bool ownBreed) external onlySalesContract {
		SuperHorse storage superStorage = superHorse[tokenId];
		
		if (ownBreed) {
			superStorage.ownBreed = 1;
		} else {
			superStorage.rented++;
		}
	}
	
    function becomeSuperHorse(uint256 tokenId) external onlySalesContract {
        Horse storage horseStorage = horse[tokenId];
        horseStorage.isSuperHorse = true;
    }

    function burnHorse(uint256 tokenId) external onlySalesContract {
        delete horse[tokenId];
    }
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}