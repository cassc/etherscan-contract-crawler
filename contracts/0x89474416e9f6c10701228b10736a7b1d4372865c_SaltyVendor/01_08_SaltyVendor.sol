// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISaltyVerse is IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract SaltyVendor is Ownable {
	using ECDSA for bytes32;

	event NFTClaimed(address user, uint256 id, uint256 amount);

	mapping(address => uint256) public addressMinted;
	
	address private _signer;

	ISaltyVerse public collection;
	uint256 public currentIdSchedule;

	constructor(address __signer, ISaltyVerse _collection) {
		_signer = __signer;
		collection = _collection;
		currentIdSchedule = 1;
	}

	// Verifies that the sender is whitelisted
	function _verifySignature(address sender, bytes memory signature) internal view returns (bool) {
		return keccak256(abi.encodePacked(sender))
			.toEthSignedMessageHash()
			.recover(signature) == _signer;
	}

	function claim(bytes memory _signature) external {
		require(_verifySignature(msg.sender, _signature), "You are not on the whitelist");
		require(addressMinted[msg.sender] < currentIdSchedule, "You have claimed");

		collection.mint(msg.sender, currentIdSchedule, 1, bytes(""));
		emit NFTClaimed(msg.sender, currentIdSchedule, 1);
		addressMinted[msg.sender] = currentIdSchedule;
	}

	function getSigner() external view returns (address) {
		return _signer;
	}

	function setIdSchedule(uint256 _currentIdSchedule) external {
		require(_currentIdSchedule > currentIdSchedule, "Can't set over the id schedule");
		currentIdSchedule = _currentIdSchedule;
	}
}