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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ITZRKT {
	function mint(address to, uint256 amount) external;

	function totalSupply() external view returns (uint256);
}

contract MintTZRKT is Ownable {
	using ECDSA for bytes32;

	// TZRKT Contract address
	address private _tzrktContract;

	// users mint count
	mapping(address => uint256) private _userMintCount;

	/**
	 * whitelist check signer address
	 */
	address private _ogBillySignerAddress;
	address private _billyPlusSignerAddress;
	address private _billySignerAddress;

	/**
	 * mint start/end time
	 */
	uint256 private _ogBillyMintStartTime;
	uint256 private _ogBillyMintEndTime;
	uint256 private _billyPlusMintStartTime;
	uint256 private _billyPlusMintEndTime;
	uint256 private _billyMintStartTime;
	uint256 private _billyMintEndTime;

	// events
	event TZRKTContractChanged(address indexed previousContract, address indexed newContract);

	constructor() {
		// Minting Time
		_ogBillyMintStartTime = 1687953600; // 2023-06-29 05:00:00 UTC
		_ogBillyMintEndTime = 1687954799; // 2023-06-29 16:59:59 UTC
		_billyPlusMintStartTime = 1687954800; // 2023-06-29 17:00:00 UTC
		_billyPlusMintEndTime = 1687955999; // 2023-06-30 04:59:59 UTC
		_billyMintStartTime = 1687956000; // 2023-06-30 05:00:00 UTC
		_billyMintEndTime = 1687957200; // 2023-06-30 17:20:00 UTC
	}

	/**
	 * @notice set address of the TZRKT NFT contract.
	 * can only be called by the owner
	 * @param newTzrktContract TZRKT NFT contract address
	 */
	function setTZRKTContract(address newTzrktContract) public onlyOwner {
		require(newTzrktContract != address(0), "setTZRKTContract: contract address is the zero address");
		address oldTzrktContract = _tzrktContract;
		_tzrktContract = newTzrktContract;
		emit TZRKTContractChanged(oldTzrktContract, newTzrktContract);
	}

	/**
	 * @notice set address of the OG Billy Signer
	 * can only be called by the owner
	 * @param newSigner address of digital signature signer
	 */
	function setOgBillySignerAddress(address newSigner) public onlyOwner {
		require(newSigner != address(0), "setOgBillySignerAddress: signer address is the zero address");
		_ogBillySignerAddress = newSigner;
	}

	/**
	 * @notice set address of the Billy Plus Signer
	 * can only be called by the owner
	 * @param newSigner address of digital signature signer
	 */
	function setBillyPlusSignerAddress(address newSigner) public onlyOwner {
		require(newSigner != address(0), "setBillyPlusSignerAddress: signer address is the zero address");
		_billyPlusSignerAddress = newSigner;
	}

	/**
	 * @notice set address of the Billy Signer
	 * can only be called by the owner
	 * @param newSigner address of digital signature signer
	 */
	function setBillySignerAddress(address newSigner) public onlyOwner {
		require(newSigner != address(0), "setBillySignerAddress: signer address is the zero address");
		_billySignerAddress = newSigner;
	}

	/**
	 * @notice set OG Billy Mint Time
	 * can only be called by the owner
	 * @param startTime mint start epoch time
	 * @param endTime mint end epoch time
	 */
	function setOgBillyMintTime(uint256 startTime, uint256 endTime) public onlyOwner {
		require(startTime < endTime, "setOgBillyMintTime: startTime is greater than endTime");
		_ogBillyMintStartTime = startTime;
		_ogBillyMintEndTime = endTime;
	}

	/**
	 * @notice set Billy Plus Mint Time
	 * can only be called by the owner
	 * @param startTime mint start epoch time
	 * @param endTime mint end epoch time
	 */
	function setBillyPlusMintTime(uint256 startTime, uint256 endTime) public onlyOwner {
		require(startTime < endTime, "setBillyPlusMintTime: startTime is greater than endTime");
		_billyPlusMintStartTime = startTime;
		_billyPlusMintEndTime = endTime;
	}

	/**
	 * @notice set Billy Mint Time
	 * can only be called by the owner
	 * @param startTime mint start epoch time
	 * @param endTime mint end epoch time
	 */
	function setBillyMintTime(uint256 startTime, uint256 endTime) public onlyOwner {
		require(startTime < endTime, "setBillyMintTime: startTime is greater than endTime");
		_billyMintStartTime = startTime;
		_billyMintEndTime = endTime;
	}

	/**
	 * @notice mint for og billy
	 * @param amount amount of mint TZRKT
	 * @param ogBillySignature digital signature of og billy
	 * @param billyPlusSignature digital signature of billy plus
	 * @param billySignature digital signature of billy
	 */
	function mintOgBilly(
		uint256 amount,
		bytes memory ogBillySignature,
		bytes memory billyPlusSignature,
		bytes memory billySignature
	) public {
		require(_tzrktContract != address(0), "mintOgBilly: _tzrktContract is the zero address.");
		require(checkOgBillyMintTime(), "mintOgBilly: not minting time");

		// signature validate
		// need og billy signature
		bool ogBillyVerified = !_isEmptyStringBytes(ogBillySignature) &&
			_verifyAddressSigner(_msgSender(), _ogBillySignerAddress, ogBillySignature);
		require(ogBillyVerified, "mintOgBilly: signature invalid");

		uint256 mintAvailableCount = getMintAvailableCount(
			_msgSender(),
			ogBillySignature,
			billyPlusSignature,
			billySignature
		);
		require(amount <= mintAvailableCount, "mintOgBilly: exceeded mint supply.");

		ITZRKT(_tzrktContract).mint(_msgSender(), amount);

		_userMintCount[_msgSender()] += amount;
	}

	/**
	 * @notice mint for billy plus
	 * @param amount amount of mint TZRKT
	 * @param ogBillySignature digital signature of og billy
	 * @param billyPlusSignature digital signature of billy plus
	 * @param billySignature digital signature of billy
	 */
	function mintBillyPlus(
		uint256 amount,
		bytes memory ogBillySignature,
		bytes memory billyPlusSignature,
		bytes memory billySignature
	) public {
		require(_tzrktContract != address(0), "mintBillyPlus: _tzrktContract is the zero address.");
		require(checkBillyPlusMintTime(), "mintBillyPlus: not minting time");

		// signature validate
		// need og billy or billy plus
		bool ogBillyVerified = !_isEmptyStringBytes(ogBillySignature) &&
			_verifyAddressSigner(_msgSender(), _ogBillySignerAddress, ogBillySignature);
		bool billyPlusVerified = !_isEmptyStringBytes(billyPlusSignature) &&
			_verifyAddressSigner(_msgSender(), _billyPlusSignerAddress, billyPlusSignature);
		require(ogBillyVerified || billyPlusVerified, "mintBillyPlus: signature invalid");

		uint256 mintAvailableCount = getMintAvailableCount(
			_msgSender(),
			ogBillySignature,
			billyPlusSignature,
			billySignature
		);
		require(amount <= mintAvailableCount, "mintBillyPlus: exceeded mint supply.");

		ITZRKT(_tzrktContract).mint(_msgSender(), amount);

		_userMintCount[_msgSender()] += amount;
	}

	/**
	 * @notice mint for billy
	 * @param amount amount of mint TZRKT
	 * @param ogBillySignature digital signature of og billy
	 * @param billyPlusSignature digital signature of billy plus
	 * @param billySignature digital signature of billy
	 */
	function mintBilly(
		uint256 amount,
		bytes memory ogBillySignature,
		bytes memory billyPlusSignature,
		bytes memory billySignature
	) public {
		require(_tzrktContract != address(0), "mintBilly: _tzrktContract is the zero address.");
		require(checkBillyMintTime(), "mintBilly: not minting time");

		// signature validate
		// need og billy or billy plus or billy
		bool ogBillyVerified = !_isEmptyStringBytes(ogBillySignature) &&
			_verifyAddressSigner(_msgSender(), _ogBillySignerAddress, ogBillySignature);
		bool billyPlusVerified = !_isEmptyStringBytes(billyPlusSignature) &&
			_verifyAddressSigner(_msgSender(), _billyPlusSignerAddress, billyPlusSignature);
		bool billyVerified = !_isEmptyStringBytes(billySignature) &&
			_verifyAddressSigner(_msgSender(), _billySignerAddress, billySignature);
		require(ogBillyVerified || billyPlusVerified || billyVerified, "mintBilly: signature invalid");

		uint256 mintAvailableCount = getMintAvailableCount(
			_msgSender(),
			ogBillySignature,
			billyPlusSignature,
			billySignature
		);
		require(amount <= mintAvailableCount, "mintBilly: exceeded mint supply.");

		ITZRKT(_tzrktContract).mint(_msgSender(), amount);

		_userMintCount[_msgSender()] += amount;
	}

	/**
	 * @notice get current block timestamp
	 */
	function getCurrentBlockTime() public view returns (uint) {
		return block.timestamp;
	}

	/**
	 * @notice check start time of OG Billy
	 */
	function checkOgBillyMintTime() public view returns (bool) {
		return _ogBillyMintStartTime <= block.timestamp && _ogBillyMintEndTime >= block.timestamp;
	}

	/**
	 * @notice check start time of Billy Plus
	 */
	function checkBillyPlusMintTime() public view returns (bool) {
		return _billyPlusMintStartTime <= block.timestamp && _billyPlusMintEndTime >= block.timestamp;
	}

	/**
	 * @notice check start time of Billy
	 */
	function checkBillyMintTime() public view returns (bool) {
		return _billyMintStartTime <= block.timestamp && _billyMintEndTime >= block.timestamp;
	}

	/**
	 * @notice get users mint available count by role
	 * @param sender address of wallet
	 * @param ogBillySignature digital signature of og billy
	 * @param billyPlusSignature digital signature of billy plus
	 * @param billySignature digital signature of billy
	 */
	function getMintAvailableCount(
		address sender,
		bytes memory ogBillySignature,
		bytes memory billyPlusSignature,
		bytes memory billySignature
	) public view returns (uint256) {
		require(sender != address(0), "getMintAvailableCount: sender address is the zero address");

		uint256 totalMintAvailableCount = _getTotalMintAvailableCount(
			sender,
			ogBillySignature,
			billyPlusSignature,
			billySignature
		);
		return totalMintAvailableCount - _userMintCount[sender];
	}

	/**
	 * @notice verify signer
	 * @param sender address of wallet
	 * @param signerAddress address of signer
	 * @param signature digital signature
	 */
	function _verifyAddressSigner(
		address sender,
		address signerAddress,
		bytes memory signature
	) private pure returns (bool) {
		bytes32 messageHash = keccak256(abi.encodePacked(sender));
		return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
	}

	/**
	 * @notice get total mint available count by role
	 * OG Billy: 2, Billy Plus: 1, Billy: 1
	 * @param sender address of wallet
	 * @param ogBillySignature digital signature of og billy
	 * @param billyPlusSignature digital signature of billy plus
	 * @param billySignature digital signature of billy
	 */
	function _getTotalMintAvailableCount(
		address sender,
		bytes memory ogBillySignature,
		bytes memory billyPlusSignature,
		bytes memory billySignature
	) private view returns (uint256) {
		uint256 availableMintAmount = 0;
		if (
			!_isEmptyStringBytes(ogBillySignature) &&
			_verifyAddressSigner(sender, _ogBillySignerAddress, ogBillySignature)
		) {
			availableMintAmount += 2;
		}
		if (
			!_isEmptyStringBytes(billyPlusSignature) &&
			_verifyAddressSigner(sender, _billyPlusSignerAddress, billyPlusSignature)
		) {
			availableMintAmount += 1;
		}
		if (!_isEmptyStringBytes(billySignature) && _verifyAddressSigner(sender, _billySignerAddress, billySignature)) {
			availableMintAmount += 1;
		}
		return availableMintAmount;
	}

	/**
	 * @notice check bytes is empty string
	 * @param data bytes data
	 */
	function _isEmptyStringBytes(bytes memory data) private pure returns (bool) {
		if (data.length == 0) {
			return true;
		}
		for (uint256 i = 0; i < data.length; i++) {
			if (data[i] != 0x00) {
				return false;
			}
		}
		return true;
	}
}