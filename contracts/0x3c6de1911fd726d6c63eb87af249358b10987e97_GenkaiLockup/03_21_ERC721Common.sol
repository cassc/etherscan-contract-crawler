// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "ERC721xUpgradeable.sol";

abstract contract ERC721Common is ERC721xUpgradeable {
	/// @dev Emitted when the token nonce is updated
  	event NonceUpdated(uint256 indexed _tokenId, uint256 indexed _nonce);

	/// @dev Mapping from token id => token nonce
	mapping(uint256 => uint256) public nonces;
	mapping(uint256 => uint256) public lockNonces;
	/**
	* @dev This empty reserved space is put in place to allow future versions to add new
	* variables without shifting down storage in the inheritance chain.
	*/
	uint256[50] private ______gap;

	function stateOf(uint256 _tokenId) external view virtual returns (bytes memory) {
		require(_exists(_tokenId), "ERC721Common: query for non-existent token");
		return abi.encodePacked(ownerOf(_tokenId), nonces[_tokenId], _tokenId, lockNonces[_tokenId]);
	}

	function lockId(uint256 _id) public override {
		lockNonces[_id]++;
		super.lockId(_id);
	}

	function unlockId(uint256 _id) public override {
		lockNonces[_id]++;
		super.unlockId(_id);
	}

	function freeId(uint256 _id, address _contract) public override {
		lockNonces[_id]++;
		super.freeId(_id, _contract);
	}

	/**
	* @dev Override `ERC721-_beforeTokenTransfer`.
	*/
	function _beforeTokenTransfer(address _from, address _to, uint256 _firstTokenId, uint256 _batchSize)
	internal
	virtual
	override
	{
		for (uint256 _tokenId = _firstTokenId; _tokenId < _firstTokenId + _batchSize; _tokenId++) {
			emit NonceUpdated(_tokenId, ++nonces[_tokenId]);
		}
		super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);
	}

}