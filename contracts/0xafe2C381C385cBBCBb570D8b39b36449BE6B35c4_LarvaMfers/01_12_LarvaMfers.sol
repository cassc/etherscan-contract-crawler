// SPDX-License-Identifier: MIT


//  _,   _, __, _,_  _,   _, _ __, __, __,  _,
//  |   /_\ |_) | / /_\   |\/| |_  |_  |_) (_
//  | , | | | \ |/  | |   |  | |   |   | \ , )
//  ~~~ ~ ~ ~ ~ ~   ~ ~   ~  ~ ~   ~~~ ~ ~  ~

// author: zhoug.eth



pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LarvaMfers is ERC721, ERC721Burnable, Ownable {
	using Strings for uint256;

	// ---------------------------------------------------------------------------------- STATE
	address public constant MFERS_ADDRESS =
		0x79FCDEF22feeD20eDDacbB2587640e45491b757f;
	address public constant LARVA_ADDRESS =
		0x5755Ab845dDEaB27E1cfCe00cd629B2e135Acc3d;
	address public withdrawAddress;

	uint256 public constant HOLDER_MINT_SUPPLY_LIMIT = 2500; // 2500 reserved for token-gated mint
	uint256 public constant FREE_MINT_SUPPLY_LIMIT = 5000; // 2500 reserved free for public mint
	uint256 public constant MAX_SUPPLY = 10000; // total available supply of all larva mfers at mint

	uint256 public maxFreeMintPerTx = 5;
	uint256 public maxPaidMintPerTx = 20;
	uint256 public totalSupply;
	uint256 public cost = 0.0069 ether;

	string internal uriPrefix;
	string public uriSuffix = ".json";
	string public hiddenURI =
		"HIDDEN: set this value as Owner with 'setHiddenURI()'";
	string public provenance;

	bool public collectionIsHidden = true;
	bool public freeMintIsActive = false;
	bool public paidMintIsActive = false;

	IERC721 internal mfersContract = IERC721(MFERS_ADDRESS);
	IERC721 internal larvaContract = IERC721(LARVA_ADDRESS);

	// ---------------------------------------------------------------------------------- the CONSTRUCTOOOR
	constructor() ERC721("larva mfers", "LARMF") {
		withdrawAddress = msg.sender;
	}

	// ---------------------------------------------------------------------------------- MODiFiERs
	modifier validateMintInput(uint256 _amountOfTokens, uint256 _maxSupply) {
		require(_amountOfTokens > 0, "Must mint at least one token");
		require(
			(totalSupply + _amountOfTokens) < (_maxSupply + 1),
			"Supply limit reached"
		);
		_;
	}

	modifier capMaxMint(uint256 _amountOfTokens, uint256 _maxMint) {
		require(
			_amountOfTokens < _maxMint + 1,
			"Transaction would exceed max mint amount"
		);
		_;
	}

	// ---------------------------------------------------------------------------------- ViEWs
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		if (collectionIsHidden) {
			return hiddenURI;
		}

		require(bytes(uriPrefix).length > 0, "uriPrefix not set");
		require(_exists(tokenId), "Token does not exist");
		return string(abi.encodePacked(uriPrefix, tokenId.toString(), uriSuffix));
	}

	function getTokensOwnedByAddress(address _address)
		public
		view
		returns (uint256[] memory ownedTokenIds)
	{
		uint256 addressBalance = balanceOf(_address);
		uint256 tokenIdCounter = 1;
		uint256 ownedTokenCounter = 0;
		ownedTokenIds = new uint256[](addressBalance);

		while (
			ownedTokenCounter < addressBalance && tokenIdCounter < MAX_SUPPLY + 1
		) {
			address tokenOwnerAddress = ownerOf(tokenIdCounter);
			if (tokenOwnerAddress == _address) {
				ownedTokenIds[ownedTokenCounter] = tokenIdCounter;
				ownedTokenCounter++;
			}
			tokenIdCounter++;
		}
	}

	// ---------------------------------------------------------------------------------- MiNTs
	function batchMint(address _recipient, uint256 _tokenAmount) internal {
		for (uint256 i = 1; i < _tokenAmount + 1; i++) {
			_safeMint(_recipient, totalSupply + i);
		}
		totalSupply += _tokenAmount;
	}

	// ~* free mint *~
	function freeMint(uint256 _amountOfTokens)
		external
		validateMintInput(_amountOfTokens, FREE_MINT_SUPPLY_LIMIT)
		capMaxMint(_amountOfTokens, maxFreeMintPerTx)
	{
		require(freeMintIsActive, "Free mint closed");

		// If token supply is less than the token-gated mint limit, validate sender's token balance
		if (totalSupply < HOLDER_MINT_SUPPLY_LIMIT) {
			require(
				mfersContract.balanceOf(msg.sender) > 0 ||
					larvaContract.balanceOf(msg.sender) > 0,
				"Free mint is currently for mfer and larva lad holders only"
			);
		}
		batchMint(msg.sender, _amountOfTokens);
	}

	// ~* paid mint *~
	function mint(uint256 _amountOfTokens)
		external
		payable
		validateMintInput(_amountOfTokens, MAX_SUPPLY)
		capMaxMint(_amountOfTokens, maxPaidMintPerTx)
	{
		require(paidMintIsActive, "Paid mint closed");
		require(
			msg.value == cost * _amountOfTokens,
			"Invalid payment amount sent: send exact value in the 'cost' property"
		);
		batchMint(msg.sender, _amountOfTokens);
	}

	// ~* owner mint *~
	function ownerMint(address _recipient, uint256 _amountOfTokens)
		external
		validateMintInput(_amountOfTokens, MAX_SUPPLY)
		onlyOwner
	{
		batchMint(_recipient, _amountOfTokens);
	}

	// ---------------------------------------------------------------------------------- OWNER FUNCTiONs
	function withdraw() external payable {
		require(
			msg.sender == withdrawAddress,
			"Withdraw must be called from the withdraw address"
		);

		(bool os, ) = payable(withdrawAddress).call{value: address(this).balance}(
			""
		);
		require(os);
	}

	function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
		withdrawAddress = _withdrawAddress;
	}

	function setURIPrefix(string memory _uriPrefix) public onlyOwner {
		require(
			!collectionIsHidden,
			"Cannot set URI while collection is hidden - use 'reveal()' to initialize and expose the URI prefix for the first time"
		);
		uriPrefix = _uriPrefix;
	}

	function setURISuffix(string memory _uriSuffix) public onlyOwner {
		uriSuffix = _uriSuffix;
	}

	function setHiddenURI(string memory _hiddenURI) public onlyOwner {
		hiddenURI = _hiddenURI;
	}

	function setProvenance(string memory _provenance) public onlyOwner {
		provenance = _provenance;
	}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	function setMaxFreeMintPerTx(uint256 _maxFreeMintPerTx) public onlyOwner {
		maxFreeMintPerTx = _maxFreeMintPerTx;
	}

	function setMaxPaidMintPerTx(uint256 _maxPaidMintPerTx) public onlyOwner {
		maxPaidMintPerTx = _maxPaidMintPerTx;
	}

	function setFreeMintIsActive(bool _state) public onlyOwner {
		freeMintIsActive = _state;
	}

	function setPaidMintIsActive(bool _state) public onlyOwner {
		paidMintIsActive = _state;
	}

	// One-way function that reveals the collection and sets the content URI
	function revealCollection(string memory _uriPrefix) public onlyOwner {
		require(collectionIsHidden, "Collection is already revealed");
		require(
			!freeMintIsActive && !paidMintIsActive,
			"Cannot reveal collection while minting is active"
		);

		collectionIsHidden = false;
		setURIPrefix(_uriPrefix);
	}
}