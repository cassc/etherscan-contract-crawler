// SPDX-License-Identifier: MIT
//
//
//  ________  ________  ________  ________  ________  _________
// |\   __  \|\   __  \|\   __  \|\   __  \|\   ____\|\___   ___\
// \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \  \___|\|___ \  \_|
//  \ \   __  \ \  \\\  \ \  \\\  \ \  \\\  \ \_____  \   \ \  \
//   \ \  \|\  \ \  \\\  \ \  \\\  \ \  \\\  \|____|\  \   \ \  \
//    \ \_______\ \_______\ \_______\ \_______\____\_\  \   \ \__\
//     \|_______|\|_______|\|_______|\|_______|\_________\   \|__|
//                                            \|_________|
//
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface ITZRKT {
	function burn(uint256 tokenId) external;

	function ownerOf(uint256 tokenId) external returns (address);
}

interface IDGVEH {
	function mint(address to) external returns (uint256);
}

contract RevealTZRKTV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
	/**
	 * V1
	 */
	// public variables
	address public _tzrktContract;
	address public _dgvehContract;

	// events
	event TZRKTContractChanged(address indexed previousContract, address indexed newContract);
	event DGVEHContractChanged(address indexed previousContract, address indexed newContract);
	event DGVEHRevealed(address indexed to, uint256 indexed tokenId);

	function initialize() public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	/**
	 * @notice set address of the TZRKT contract.
	 * can only be called by owner
	 * @param newTzrktContract address of TZRKT contract
	 */
	function setTZRKTContract(address newTzrktContract) public onlyOwner {
		require(newTzrktContract != address(0), "setTZRKTContract: contract address is the zero address");
		address oldTzrktContract = _tzrktContract;
		_tzrktContract = newTzrktContract;
		emit TZRKTContractChanged(oldTzrktContract, newTzrktContract);
	}

	/**
	 * @notice set address of the DGVEH contract.
	 * can only be called by owner
	 * @param newDgvehContract address of DGVEH contract
	 */
	function setDGVEHContract(address newDgvehContract) public onlyOwner {
		require(newDgvehContract != address(0), "setDGVEHContract: contract address is the zero address");
		address oldDgvehContract = _dgvehContract;
		_dgvehContract = newDgvehContract;
		emit DGVEHContractChanged(oldDgvehContract, newDgvehContract);
	}

	/**
	 * reveal TZRKT -> DGVEH
	 */
	function revealToDGVEH(uint256 tzrktTokenId) public returns (uint256) {
		require(_tzrktContract != address(0), "revealToDGVEH: _tzrktContract is the zero address.");
		require(_dgvehContract != address(0), "revealToDGVEH: _dgvehContract is the zero address.");

		address tzrktOwner = ITZRKT(_tzrktContract).ownerOf(tzrktTokenId);
		if (tzrktOwner != _msgSender()) revert();

		ITZRKT(_tzrktContract).burn(tzrktTokenId);

		uint256 dgvehTokenId = IDGVEH(_dgvehContract).mint(_msgSender());

		emit DGVEHRevealed(_msgSender(), dgvehTokenId);

		return dgvehTokenId;
	}
}