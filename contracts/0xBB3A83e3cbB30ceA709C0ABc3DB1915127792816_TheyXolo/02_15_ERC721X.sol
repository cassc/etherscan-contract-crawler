// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title ERC721X
/// @author cesargdm.eth

import 'erc721a/contracts/ERC721A.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

contract ERC721X is ERC721A, Ownable, ReentrancyGuard, ERC2981 {
	using Strings for uint256;

	enum MintPhase {
		Idle,
		Private,
		Public
	}

	MintPhase public mintPhase = MintPhase.Idle;

	uint256 public immutable costPerPublicMint;
	uint256 public immutable costPerPrivateMint;

	uint256 public immutable maxPerWalletPrivateMint;
	uint256 public immutable maxPerTx;
	uint256 public immutable maxTokenSupply;

	string public contractURI;
	string public tokenURIPrefix;
	string private constant tokenURIPostfix = '.json';

	bytes32 public merkleRoot;

	/**
	 * @param _name Collection name (immutable)
	 * @param _symbol Collection symbol (immutable)
	 * @param _maxTokenSupply How many tokens can be minted (immutable)
	 * @param _costPerPublicMint Cost per public token mint in wei (immutable)
	 * @param _costPerPrivateMint Cost per private token mint cost in wei (immutable)
	 * @param _maxPerTx How many token can be minted in a transaction (immutable)
	 * @param _maxPerWalletPrivateMint A limitation per wallet (immutable)
	 * @param _defaultRoyalty Default basis points of the default royalty for ERC2981,
	 * by default the owner will be the benefeciary
	 * @param _tokenURIPrefix Base URI for metadata
	 */
	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _maxTokenSupply,
		uint256 _costPerPublicMint,
		uint256 _costPerPrivateMint,
		uint256 _maxPerTx,
		uint256 _maxPerWalletPrivateMint,
		uint96 _defaultRoyalty,
		string memory _tokenURIPrefix,
		string memory _contractURI
	) ERC721A(_name, _symbol) {
		// Add 1 to the variables to save in one extra logic operator (greater than vs greater or equal)
		maxTokenSupply = _maxTokenSupply + 1;

		costPerPublicMint = _costPerPublicMint;
		costPerPrivateMint = _costPerPrivateMint;

		maxPerTx = _maxPerTx + 1;
		maxPerWalletPrivateMint = _maxPerWalletPrivateMint + 1;

		tokenURIPrefix = _tokenURIPrefix;
		contractURI = _contractURI;

		_setDefaultRoyalty(msg.sender, _defaultRoyalty);
	}

	/*

			M O D I F I E R S

	*/

	/**
	 * @notice Ensure function cannot be called outside of a given mint phase
	 * @param _mintPhase Correct mint phase for function to execute
	 */
	modifier phaseCompliance(MintPhase _mintPhase) {
		//// CHECKS ////
		require(mintPhase == _mintPhase, 'ERC721X: mintPhase invalid');

		_; // _: call the instructions after the check
	}

	/**
	 * @notice Ensure mint complies to amount, maxPerTx and maxTokenSupply restrictions
	 * @param _amount Amount of tokens to mint
	 */
	modifier amountCompliance(uint256 _amount) {
		require(_amount > 0, 'ERC721X: amount invalid');
		require(_amount < maxPerTx, 'ERC721X: maxPerTx exceeded');

		// Check total supply is not exceeded
		require(
			_totalMinted() + _amount < maxTokenSupply,
			'ERC721X: maxTokenSupply exceeded'
		);

		_;
	}

	/*

			M I N T

	*/

	/**
	 * @notice Requires Public mint phase
	 * @dev Mint a new token for the given address.
	 * @param _amount The amount of tokens to mint.
	 */
	function publicMint(uint256 _amount)
		external
		payable
		nonReentrant
		phaseCompliance(MintPhase.Public)
		amountCompliance(_amount)
	{
		//// CHECKS ////
		require(msg.value == costPerPublicMint * _amount, 'ERC721X: value invalid');

		//// INTERACTIONS ////
		_safeMint(msg.sender, _amount);
	}

	/**
	 * @notice Requires Private mint phase
	 * @param _amount Number of tokens to mint
	 * @param _proof Merkle proof to verify msg.sender is part of the presaleList
	 */
	function privateMint(uint256 _amount, bytes32[] calldata _proof)
		external
		payable
		nonReentrant
		phaseCompliance(MintPhase.Private)
		amountCompliance(_amount)
	{
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

		//// CHECKS ////
		require(
			MerkleProof.verify(_proof, merkleRoot, leaf),
			'ERC721X: proof invalid'
		);
		require(
			_getAux(msg.sender) + _amount < maxPerWalletPrivateMint,
			'ERC721X: maxPerWalletPrivateMint exceeded'
		);

		//// EFFECTS ////
		incrementRedemptionsAllowlist(_amount);

		//// INTERACTIONS ////
		_safeMint(msg.sender, _amount);
	}

	/*

			G E T T E R S

	*/

	/**
	 * @dev Override default tokenURI logic to append .json extension
	 */
	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		//// CHECKS ////
		require(
			_exists(_tokenId),
			'ERC721Metadata: URI query for nonexistent token'
		);

		return
			string(
				abi.encodePacked(tokenURIPrefix, _tokenId.toString(), tokenURIPostfix)
			);
	}

	/*

			S E T T E R S

	*/

	/**
	 * @notice Set the presaleList Merkle root in contract storage
	 * @notice Only callable by owner
	 * @param _merkleRoot New Merkle root hash
	 */
	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
		merkleRoot = _merkleRoot;
	}

	/**
	 * @notice Set the state machine mint phase
	 * @notice Only callable by owner
	 * @param _mintPhase New mint phase
	 */
	function setMintPhase(MintPhase _mintPhase) external onlyOwner {
		//// INTERACTIONS ////
		mintPhase = _mintPhase;
	}

	/**
	 * @notice Set contract tokenURIPrefix
	 * @notice Only callable by owner
	 * @param _tokenURIPrefix New tokenURIPrefix
	 */
	function setBaseTokenURI(string calldata _tokenURIPrefix) external onlyOwner {
		//// INTERACTIONS ////
		tokenURIPrefix = _tokenURIPrefix;
	}

	/**
	 * @notice Set contract collectionURI
	 * @notice Only callable by owner
	 * @param _contractURI New collectionURI
	 */
	function setContractURI(string calldata _contractURI) external onlyOwner {
		//// INTERACTIONS ////
		contractURI = _contractURI;
	}

	/**
	 * @notice Only callable by owner
	 * @dev Changes the global royalty default.
	 * @param _address New default royalty beneficiary address.
	 * @param _defaultRoyalty New default royalty value in basis points
	 */
	function setDefaultRoyalty(address _address, uint96 _defaultRoyalty)
		external
		onlyOwner
	{
		//// INTERACTIONS ////
		_setDefaultRoyalty(_address, _defaultRoyalty);
	}

	/**
	 * @notice Only callable by owner
	 * @dev Sets the royalty information for a specific token id, overriding the global default.
	 *
	 * Requirements:
	 *
	 * - `receiver` cannot be the zero address.
	 * - `feeNumerator` cannot be greater than the fee denominator.
	 */
	function setTokenRoyalty(
		uint256 _tokenId,
		address _receiver,
		uint96 _feeNumerator
	) external onlyOwner {
		//// INTERACTIONS ////
		_setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
	}

	/**
	 * @notice Only callable by owner
	 * @dev Resets royalty information for the token id back to the global default.
	 */
	function resetTokenRoyalty(uint256 _tokenId) external onlyOwner {
		//// INTERACTIONS ////
		_resetTokenRoyalty(_tokenId);
	}

	/* 

			A D M I N

	*/

	/**
	 * @notice Withdraw all current funds to the contract owner address
	 * @notice Only callable by owner
	 * @dev Withdraw all current funds to the contract owner address
	 */
	function withdraw() external onlyOwner {
		//// INTERACTIONS ////
		(bool os, ) = payable(owner()).call{ value: address(this).balance }('');
		require(os, 'ERC721X: withdraw failed');
	}

	/*

			U T I L I T I E S

	*/

	/**
	 * @notice Increment number of presaleList token mints redeemed by caller
	 * @dev We cast the _numToIncrement argument into uint32, which will not be an issue as
	 * mint quantity should never be greater than 2^32 - 1.
	 * @dev Number of redemptions are stored in ERC721A auxillary storage, which can help
	 * remove an extra cold SLOAD and SSTORE operation. Since we're storing two values
	 * (public and presaleList redemptions) we need to pack and unpack two uint32s into a single uint256.
	 * See https://chiru-labs.github.io/ERC721A/#/erc721a?id=addressdata
	 */
	function incrementRedemptionsAllowlist(uint256 _numToIncrement) private {
		uint64 presaleListMintRedemptions = _getAux(msg.sender);

		presaleListMintRedemptions += uint64(_numToIncrement);

		//// INTERACTIONS ////
		_setAux(msg.sender, presaleListMintRedemptions);
	}

	/**
	 * @dev Set token id start at 1, default is 0
	 */
	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	/**
	 * @dev Override to support IERC2981 and ERC721A interface
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC2981, ERC721A)
		returns (bool)
	{
		return
			interfaceId == type(IERC2981).interfaceId ||
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}
}