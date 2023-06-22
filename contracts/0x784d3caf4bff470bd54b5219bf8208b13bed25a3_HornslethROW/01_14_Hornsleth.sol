// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721ABurnable.sol";

contract HornslethROW is ERC721ABurnable, Ownable {
	string private _collectionURI;
	string private baseURI;
	using Strings for uint;
	string public baseExtension = ".json";
	string private notRevealedUri;
	uint public PRICE = 0.1 ether;
	uint public WHITELIST_PRICE = 0.08 ether;
	uint public MAX_SUPPLY = 1111;
	uint public MAX_TOKEN_PER_TRANSACTION = 3;
	uint public MAX_CROSSMINT_AMOUNT_PER_TX = 1;

	uint public PREMINT_PER_ADDRESS_LIMIT = 3;
	address private _crossmintAddress =
		0xdAb1a1854214684acE522439684a145E62505233;
	bytes32 public merkleRoot =
		0xd66a5204bdfd01f2e334cac8a16d9ef4006c78884095e1844474d98ba399a41a;
	bool public revealed = false;
	bool public _paused = false;
	bool public _isPresale = false;
	bool public _isPublicsale = false;

	address payable private Admin1 = // KvH
		payable(0x830540d74C24534e83b3e34C18EB3faa0b37fa1a);

	mapping(address => uint) public addressMintedBalance;
	mapping(address => bool) private canWithdraw;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initNotRevealedUri
	) ERC721A(_name, _symbol) {
		setNotRevealedURI(_initNotRevealedUri);
		canWithdraw[Admin1] = true;
	}

	modifier onlyAdmins() {
		if (canWithdraw[msg.sender]) {
			_;
		} else {
			revert("This action is reserved for Admins");
		}
	}

	receive() external payable {}

	fallback() external payable {}

	// public
	function tokenURI(uint tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		if (revealed == false) {
			return notRevealedUri;
		}
		return
			bytes(baseURI).length != 0
				? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
				: "";
	}

	function mint(uint _mintAmount, bytes32[] memory proof) external payable {
		require(!_paused, "the contract is paused");
		require(_mintAmount > 0, "need to mint at least 1 NFT");

		uint supply = totalSupply();
		require(supply + _mintAmount <= MAX_SUPPLY, "max NFT limit exceeded");

		if (msg.sender != owner()) {
			if (_isPresale == true && _isPublicsale == false) {
				require(
					_mintAmount <= MAX_TOKEN_PER_TRANSACTION,
					"max mint amount per session exceeded"
				);
				require(
					MerkleProof.verify(
						proof,
						merkleRoot,
						keccak256(abi.encodePacked(msg.sender))
					),
					"Address is not whitelisted"
				);
				uint ownerMintedCount = addressMintedBalance[msg.sender];
				require(
					ownerMintedCount + _mintAmount <= PREMINT_PER_ADDRESS_LIMIT,
					"max NFT per address exceeded"
				);
				require(
					msg.value >= WHITELIST_PRICE * _mintAmount,
					"insufficient funds"
				);
				addressMintedBalance[msg.sender] += _mintAmount;
				_safeMint(msg.sender, _mintAmount);
				return;
			} else if (_isPublicsale == true) {
				require(msg.value >= PRICE * _mintAmount, "insufficient funds");
				addressMintedBalance[msg.sender] += _mintAmount;
				_safeMint(msg.sender, _mintAmount);
				return;
			} else {
				revert("The sale has not started!");
			}
		}

		addressMintedBalance[msg.sender] += _mintAmount;
		_safeMint(msg.sender, _mintAmount);
	}

	function crossmint(address to, uint _count) external payable {
		require(
			msg.sender == _crossmintAddress,
			"This function is for Crossmint only."
		);
		require(to != address(0x0), "Destination address should be valid");
		require(
			_count <= MAX_CROSSMINT_AMOUNT_PER_TX,
			"Count exceeded max tokens per transaction."
		);
		require(!_paused, "Sale is currently paused.");
		require(!_isPresale, "Public sale has not started.");

		uint supply = totalSupply();
		require(supply + _count <= MAX_SUPPLY, "Exceeds max supply.");
		require(msg.value >= PRICE * _count, "Ether sent is not correct.");
		_safeMint(to, _count);
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function reveal() public onlyOwner {
		revealed = true;
	}

	function setPremintPerAddressLimit(uint _limit) public onlyOwner {
		PREMINT_PER_ADDRESS_LIMIT = _limit;
	}

	function setMaxTokenPerTransaction(uint _newmaxMintAmount) public onlyOwner {
		MAX_TOKEN_PER_TRANSACTION = _newmaxMintAmount;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function setCrossmintMaxAmountPerTransaction(uint _newMaxCrossmintAmount)
		public
		onlyOwner
	{
		MAX_CROSSMINT_AMOUNT_PER_TX = _newMaxCrossmintAmount;
	}

	function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
		// Needs 0x infront of it!
		merkleRoot = _newMerkleRoot;
	}

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedUri = _notRevealedURI;
	}

	function pause(bool _state) public onlyOwner {
		_paused = _state;
	}

	function setIsPresale(bool _state) public onlyOwner {
		_isPresale = _state;
	}

	function setIsPublicSale(bool _state) public onlyOwner {
		_isPublicsale = _state;
	}

	/**
	 * @dev set collection URI for marketplace display
	 */
	function setCollectionURI(string memory collectionURI)
		internal
		virtual
		onlyOwner
	{
		_collectionURI = collectionURI;
	}

	function withdraw() public payable onlyAdmins {
		require(msg.sender == 0x830540d74C24534e83b3e34C18EB3faa0b37fa1a);
		(bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(os);
	}
}