// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IVestaNFT {
	error AlreadyClaimed(address _caller, uint8 _tier);
	error InvalidMerkleProof(address _caller, uint8 _tier);
	error ZeroMerkleRootPassed();
	error MerkleRootNotInitialized();

	event MerkleRootChanged(bytes32 _merkleRoot);
	event NFTClaimed(address _addr, uint8 _tier);

	/** 
	@notice setMerkleRoot is used to define who is eligible for the NFT airdrop
	@dev onlyOwner can execute this function
	@param _newRoot Generated Merkle Root of the eligible users
	*/
	function setMerkleRoot(bytes32 _newRoot) external;

	/** 
	@notice hasClaimedNFT to verify if a wallet already claimed a specific NFT Tier
	@param _user user wallet
	@param _tier V-Card tier
	@return hasBeenClaimed returns true if the user already claimed it
	*/
	function hasClaimedNFT(address _user, uint8 _tier)
		external
		view
		returns (bool);

	/** 
	@notice claimNFT to mint the nft by tier via a merkle proof
	@param _merkleProof generated merkle proof
	@param _tier V-Card tier
	*/
	function claimNFT(bytes32[] calldata _merkleProof, uint8 _tier) external;
}