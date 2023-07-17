// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "ERC721.sol";
import "LockRegistry.sol";
import "IERC721x.sol";

contract ERC721x is ERC721, LockRegistry {

	/*
	 *     bytes4(keccak256('freeId(uint256,address)')) == 0x94d216d6
	 *     bytes4(keccak256('isUnlocked(uint256)')) == 0x72abc8b7
	 *     bytes4(keccak256('lockCount(uint256)')) == 0x650b00f6
	 *     bytes4(keccak256('lockId(uint256)')) == 0x2799cde0
	 *     bytes4(keccak256('lockMap(uint256,uint256)')) == 0x2cba8123
	 *     bytes4(keccak256('lockMapIndex(uint256,address)')) == 0x09308e5d
	 *     bytes4(keccak256('unlockId(uint256)')) == 0x40a9c8df
	 *     bytes4(keccak256('approvedContract(address)')) == 0xb1a6505f
	 *
	 *     => 0x94d216d6 ^ 0x72abc8b7 ^ 0x650b00f6 ^ 0x2799cde0 ^
	 *        0x2cba8123 ^ 0x09308e5d ^ 0x40a9c8df ^ 0xb1a6505f == 0x706e8489
	 */

	bytes4 private constant _INTERFACE_ID_ERC721x = 0x706e8489;

	constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
	}

	function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721) returns (bool) {
		return _interfaceId == _INTERFACE_ID_ERC721x
			|| super.supportsInterface(_interfaceId);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public override virtual {
		require(isUnlocked(_tokenId), "Token is locked");
		ERC721.transferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override virtual {
		require(isUnlocked(_tokenId), "Token is locked");
		ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
	}

	function lockId(uint256 _id) external override virtual {
		require(_exists(_id), "Token !exist");
		_lockId(_id);
	}

	function unlockId(uint256 _id) external override virtual {
		require(_exists(_id), "Token !exist");
		_unlockId(_id);
	}

	function freeId(uint256 _id, address _contract) external override virtual {
		require(_exists(_id), "Token !exist");
		_freeId(_id, _contract);
	}
}