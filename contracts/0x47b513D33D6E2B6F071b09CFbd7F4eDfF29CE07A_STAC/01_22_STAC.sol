// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IGROWOPERATION {
	function randomFedApeOwner(uint256 seed) external view returns (address);

	function stake(uint256 tokenID) external;
}

interface IRandomizer {
	function random(
		uint256 from,
		uint256 to,
		uint256 salty
	) external view returns (uint256);
}

// struct to store each token's traits
struct FedApe {
	bool isFed; //rest is handled in api/ipfs
	uint256 alphaRank; //1-10
}

interface ISTAC {
	function getPaidTokens() external view returns (uint256);

	function getTokenTraits(uint256 tokenId) external view returns (bool, uint256);
}

interface ITOKE {
	function burn(address from, uint256 amount) external;
}

contract STAC is ISTAC, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard, PaymentSplitter {
	using Address for address;
	using Strings for uint256;
	using Counters for Counters.Counter;
	using MerkleProof for bytes32[];

	struct LastWrite {
		uint64 time;
		uint64 blockNum;
	}
	// Tracks the last block and timestamp that a caller has written to state.
	// Disallow some access to functions if they occur while a change is being written.
	mapping(address => LastWrite) private lastWriteAddress;
	mapping(uint256 => LastWrite) private lastWriteToken;

	event StonedApeMinted(uint256 indexed tokenId, address indexed minter, address indexed owner);
	event FedApeMinted(uint256 indexed tokenId, address indexed minter, address indexed owner);
	event StonedApeBurned(uint256 indexed tokenId);
	event FedApeBurned(uint256 indexed tokenId);

	//the merkle root
	bytes32 public root = 0x239716006b91b10b09f232833bd24ba204e07c9b706043479063ec53d9458e44;

	uint256 public whitelistStartTime = 14220329;
	uint256 public publicSaleStartTime = 14223329;

	// mint price
	uint256 public MINT_PRICE = .15 ether;
	// whitelist mint price
	uint256 public WL_MINT_PRICE = .08 ether;
	// max number of tokens that can be minted - 50000 in production
	uint256 public immutable MAX_TOKENS = 50000;
	// max number of tokens that a whitelisted user can mint
	uint256 public MAX_WL_TOKENS = 2;
	// number of tokens that can be claimed for free - 20% of MAX_TOKENS
	uint256 public PAID_TOKENS = 10000;

	// mapping from user's address to amount whitelist minted
	mapping(address => uint256) public amountWhitelisted;
	// mapping from tokenId to a struct containing the token's traits
	mapping(uint256 => FedApe) private tokenTraits;

	IRandomizer private randomizer;

	// reference to the Grow Operation for choosing random Fed Apes
	IGROWOPERATION public growOperation;
	// reference to $TOKE for burning on mint
	ITOKE public tokeERC20;
	address private devWallet;
	Counters.Counter private _tokenIds;

	//payment splitter
	address[] private addressList = [
		0x4E12FCeCe183316cbdA2fB31bBeBdB8127460444, //F
		0x418a3c6DF48EDbEDc7C2B9C59cF7Baea2E57C260 //D
	];
	uint256[] private shareList = [92, 8];

	bool public locked; //metadata lock
	string public _contractBaseURI = "https://api.stonedapeclub.com/v1/nft/metadata/";
	string public _contractURI =
		"ipfs://QmRFw3qmTmyRWcRpDJjUeHLCdADTZfY17CK2hfi11tXrNw";

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev");
		_;
	}

	modifier blockIfChangingAddress() {
		require(lastWriteAddress[tx.origin].blockNum < block.number, "hmmmm what doing?");
		_;
	}

	modifier blockIfChangingToken(uint256 tokenId) {
		require(lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
		_;
	}

	constructor() ERC721("Stoned Ape Club", "STAC") PaymentSplitter(addressList, shareList) {
		devWallet = msg.sender;
	}

	/**
	 * @dev you need to be whitelisted and know the proof to be able to mint
	 */
	function whitelistMint(
		uint256 qty,
		uint256 tokenId,
		uint256 _seed,
		bytes32[] calldata proof
	) external payable nonReentrant {
		require(block.timestamp > whitelistStartTime, "not live");
		require(isTokenValid(msg.sender, tokenId, proof), "invalid proof");
		require(tx.origin == msg.sender, "no...");
		require(_tokenIds.current() + qty <= MAX_TOKENS, "All tokens minted");
		require(qty <= 2, "Invalid mint qty");
		require(amountWhitelisted[msg.sender] + qty <= MAX_WL_TOKENS, "You already minted your whitelist tokens");

		if (_tokenIds.current() < PAID_TOKENS) {
			//if tokens are sold with ETH
			require(_tokenIds.current() + qty <= PAID_TOKENS, "All tokens on-sale already sold");
			require(qty * WL_MINT_PRICE == msg.value, "Invalid payment amount");
		} else {
			require(msg.value == 0);
		}

		uint256 seed;

		for (uint256 i = 0; i < qty; i++) {
			seed = randomizer.random(1000, 100**17 + 75, _seed + _tokenIds.current());
			address recipient = selectRecipient(seed);
			uint256 totalTokeCost = mintCost(totalSupply() + 1);

			if (totalTokeCost > 0) {
				tokeERC20.burn(_msgSender(), totalTokeCost);
			}

			_tokenIds.increment();

			//set the token traits
			uint256 isStonedApeInt = seed % 100; //90% Stoned Ape
			uint256 alpha = 1;
			bool isFed = false;
			if (isStonedApeInt >= 89) {
				isFed = true;
				emit FedApeMinted(_tokenIds.current(), msg.sender, recipient);
			} else {
				emit StonedApeMinted(_tokenIds.current(), msg.sender, recipient);
			}
			alpha = (isStonedApeInt % 10) + 1; //rank 1-10

			FedApe memory sw = FedApe(isFed, alpha);
			tokenTraits[_tokenIds.current()] = sw;

			updateOriginAccess(_tokenIds.current());
			_safeMint(recipient, _tokenIds.current());
			amountWhitelisted[msg.sender]++;
		}
	}

	/**
	 * Mint a token - 90% Stoned Ape, 10% Fed Ape
	 * The first 20% are free to claim, the remaining cost $TOKE
	 */
	function mint(uint256 qty, uint256 _seed) external payable whenNotPaused nonReentrant {
		require(tx.origin == msg.sender, "no...");
		require(_tokenIds.current() + qty <= MAX_TOKENS, "All tokens minted");
		require(qty <= 20, "Invalid mint qty");
		require(block.timestamp > publicSaleStartTime, "not live");

		if (_tokenIds.current() < PAID_TOKENS) {
			//if tokens are sold with ETH
			require(_tokenIds.current() + qty <= PAID_TOKENS, "All tokens on-sale already sold");
			require(qty * MINT_PRICE == msg.value, "Invalid payment amount");
		} else {
			require(msg.value == 0);
		}

		uint256 seed;

		for (uint256 i = 0; i < qty; i++) {
			seed = randomizer.random(1000, 100**17 + 75, _seed + _tokenIds.current());
			address recipient = selectRecipient(seed);
			uint256 totalTokeCost = mintCost(totalSupply() + 1);

			if (totalTokeCost > 0) {
				tokeERC20.burn(_msgSender(), totalTokeCost);
			}

			_tokenIds.increment();

			//set the token traits
			uint256 isStonedApeInt = seed % 100; //90% Stoned Ape
			uint256 alpha = 1;
			bool isFed = false;
			if (isStonedApeInt >= 89) {
				isFed = true;
				emit FedApeMinted(_tokenIds.current(), msg.sender, recipient);
			} else {
				emit StonedApeMinted(_tokenIds.current(), msg.sender, recipient);
			}
			alpha = (isStonedApeInt % 10) + 1; //rank 1-10

			FedApe memory sw = FedApe(isFed, alpha);
			tokenTraits[_tokenIds.current()] = sw;

			updateOriginAccess(_tokenIds.current());
			_safeMint(recipient, _tokenIds.current());
		}
	}

	/**
	 * the first are paid in ETH, then in $TOKE
	 * @param tokenId the ID to check the cost of to mint
	 * @return the cost of the given token ID
	 */
	function mintCost(uint256 tokenId) public view returns (uint256) {
		if (tokenId <= PAID_TOKENS) return 0;
		if (tokenId <= (MAX_TOKENS * 2) / 5) return 20000 ether;
		if (tokenId <= (MAX_TOKENS * 4) / 5) return 40000 ether;
		return 80000 ether;
	}

	/**
	 * the first 20% (ETH purchases) go to the minter
	 * 10% chance to be given to a random staked Fed Ape
	 * @param seed a random value to select a recipient from
	 * @return the address of the recipient (either the minter or the Fed Apes's owner)
	 */
	function selectRecipient(uint256 seed) internal view returns (address) {
		seed = randomizer.random(1000, 100**17 + 75, seed + _tokenIds.current());
		if (totalSupply() <= PAID_TOKENS) return _msgSender();
		if (seed % 100 < 90) {
			//there's a high chance you'll get the token ;)
			return _msgSender();
		}
		address thief = growOperation.randomFedApeOwner(seed);
		if (thief == address(0x0)) {
			return _msgSender();
		}
		return thief;
	}

	/** READ */
	function getPaidTokens() external view override returns (uint256) {
		return PAID_TOKENS;
	}

	function getTokenTraits(uint256 tokenId)
		public
		view
		override
		blockIfChangingAddress
		blockIfChangingToken(tokenId)
		returns (bool, uint256)
	{
		return (tokenTraits[tokenId].isFed, tokenTraits[tokenId].alphaRank);
	}

	/** ADMIN */
	/**
	 * called after deployment so that the contract can get random Fed Apes
	 * @param _growOperationAddress the address of the Grow Operation
	 */
	function setGrowOperation(address _growOperationAddress) external onlyOwner {
		growOperation = IGROWOPERATION(_growOperationAddress);
	}

	function setToke(address _newTokeAddress) external onlyOwner {
		tokeERC20 = ITOKE(_newTokeAddress);
	}

	function setRandomizer(address _newRandomizer) external onlyOwner {
		randomizer = IRandomizer(_newRandomizer);
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}

	// don't have to waste gas approving
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override(ERC721) blockIfChangingToken(tokenId) {
		if (_msgSender() != address(growOperation))
			require(
				_isApprovedOrOwner(_msgSender(), tokenId),
				"ERC721: transfer caller is not owner nor approved"
			);
		_transfer(from, to, tokenId);
	}

	//----------------------------------
	//----------- other code -----------
	//----------------------------------

	function isTokenValid(
		address _to,
		uint256 _tokenId,
		bytes32[] memory _proof
	) public view returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));
		// verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}

	function getTokenWriteBlock(uint256 tokenId) external view returns (uint64) {
		return lastWriteToken[tokenId].blockNum;
	}

	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function burn(uint256 tokenId) external whenNotPaused {
		require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
		if (tokenTraits[tokenId].isFed) {
			emit FedApeBurned(tokenId);
		} else {
			emit StonedApeBurned(tokenId);
		}
		_burn(tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

	function setBaseURI(string memory newBaseURI) external onlyDev {
		require(!locked, "locked functions");
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyDev {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function changePricePerToken(uint256 newPrice) external onlyOwner {
		MINT_PRICE = newPrice;
	}

	function changeWLPricePerToken(uint256 newPrice) external onlyOwner {
		WL_MINT_PRICE = newPrice;
	}

	function setPaidTokensAmount(uint256 newAmount) external onlyOwner {
		PAID_TOKENS = newAmount;
	}

	function setWhitelistStartTime(uint256 newTime) external onlyOwner {
		whitelistStartTime = newTime;
	}

	function setPublicSaleStartTime(uint256 newTime) external onlyOwner {
		publicSaleStartTime = newTime;
	}
	function changeWLAmountMax(uint256 newAmount) external onlyOwner {
		MAX_WL_TOKENS = newAmount;
	}

	// Locks metadata
	function lockMetadata() external onlyDev {
		locked = true;
	}

	/** OVERRIDES FOR SAFETY */
	function updateOriginAccess(uint256 tokenId) internal {
		uint64 blockNum = uint64(block.number);
		uint64 time = uint64(block.timestamp);
		lastWriteAddress[tx.origin] = LastWrite(time, blockNum);
		lastWriteToken[tokenId] = LastWrite(time, blockNum);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index)
		public
		view
		virtual
		override(ERC721Enumerable)
		blockIfChangingAddress
		returns (uint256)
	{
		require(lastWriteAddress[owner].blockNum < block.number, "hmmmm what doing?");
		uint256 tokenId = super.tokenOfOwnerByIndex(owner, index);
		require(lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
		return tokenId;
	}

	function balanceOf(address owner)
		public
		view
		virtual
		override(ERC721)
		blockIfChangingAddress
		returns (uint256)
	{
		require(lastWriteAddress[owner].blockNum < block.number, "hmmmm what doing?");
		return super.balanceOf(owner);
	}

	function ownerOf(uint256 tokenId)
		public
		view
		virtual
		override(ERC721)
		blockIfChangingAddress
		blockIfChangingToken(tokenId)
		returns (address)
	{
		address addr = super.ownerOf(tokenId);
		require(lastWriteAddress[addr].blockNum < block.number, "hmmmm what doing?");
		return addr;
	}

	function tokenByIndex(uint256 index)
		public
		view
		virtual
		override(ERC721Enumerable)
		returns (uint256)
	{
		uint256 tokenId = super.tokenByIndex(index);
		require(lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
		return tokenId;
	}

	function approve(address to, uint256 tokenId)
		public
		virtual
		override(ERC721)
		blockIfChangingToken(tokenId)
	{
		super.approve(to, tokenId);
	}

	function getApproved(uint256 tokenId)
		public
		view
		virtual
		override(ERC721)
		blockIfChangingToken(tokenId)
		returns (address)
	{
		return super.getApproved(tokenId);
	}

	function setApprovalForAll(address operator, bool approved)
		public
		virtual
		override(ERC721)
		blockIfChangingAddress
	{
		super.setApprovalForAll(operator, approved);
	}

	function isApprovedForAll(address owner, address operator)
		public
		view
		virtual
		override(ERC721)
		blockIfChangingAddress
		returns (bool)
	{
		return super.isApprovedForAll(owner, operator);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override(ERC721) blockIfChangingToken(tokenId) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public virtual override(ERC721) blockIfChangingToken(tokenId) {
		super.safeTransferFrom(from, to, tokenId, _data);
	}
}