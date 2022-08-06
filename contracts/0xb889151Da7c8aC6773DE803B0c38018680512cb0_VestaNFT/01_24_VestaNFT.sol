// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./interfaces/IVestaNFT.sol";
import "./layerzero/ONFT721.sol";

contract VestaNFT is ONFT721, IVestaNFT {
	string public contractURI;
	string[] private URIs;

	uint256[] private offsetTierIds = [0, 1_000_000, 2_000_000];
	uint256[] private nextTokenIds;

	bytes32 public merkleRoot;

	mapping(bytes32 => bool) internal claimed;

	constructor(
		string memory _name,
		string memory _symbol,
		address _layerZeroEndpoint,
		string[] memory _uris,
		string memory _contractURI
	) ONFT721(_name, _symbol, _layerZeroEndpoint) {
		nextTokenIds = new uint256[](3);
		URIs = _uris;
		contractURI = _contractURI;
	}

	function setCollectionDescription(string memory _contractURI)
		external
		onlyOwner
	{
		contractURI = _contractURI;
	}

	function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
		if (_newRoot == bytes32(0)) {
			revert ZeroMerkleRootPassed();
		}
		merkleRoot = _newRoot;
		emit MerkleRootChanged(_newRoot);
	}

	function hasClaimedNFT(address _user, uint8 _tier)
		external
		view
		override
		returns (bool)
	{
		return claimed[keccak256(abi.encodePacked(_user, _tier))];
	}

	function claimNFT(bytes32[] calldata _merkleProof, uint8 _tier)
		external
		override
	{
		//Removed, Arbitrum (0xe3c5D8349473Fe81a259257a5B5019493F98C217) is the only one with this option
	}

	function _mint(uint8 _tier) internal {
		uint256 tokenId = offsetTierIds[_tier] + nextTokenIds[_tier];
		nextTokenIds[_tier] += 1;

		_safeMint(msg.sender, tokenId);
		_setTokenURI(tokenId, URIs[_tier]);

		emit NFTClaimed(msg.sender, _tier);
	}

	function _creditTo(
		uint16,
		address _toAddress,
		uint256 _tokenId
	) internal override {
		uint256 offsetTier2 = offsetTierIds[2];
		uint256 tier = 0;

		if (_tokenId >= offsetTierIds[1] && _tokenId < offsetTier2) {
			tier = 1;
		} else if (_tokenId >= offsetTier2) {
			tier = 2;
		}

		_safeMint(_toAddress, _tokenId);
		_setTokenURI(_tokenId, URIs[tier]);
	}
}