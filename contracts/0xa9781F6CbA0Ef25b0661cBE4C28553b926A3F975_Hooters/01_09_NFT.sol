// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Hooters is ERC721AQueryable, Ownable {
	using SafeMath for uint256;
	enum SaleState {
		None,
		Private,
		Public
	}

	uint256 public constant PRIVATE_SALE_SUPPLY = 1350;
	uint256 public constant RESERVE_SUPPLY = 30;
	uint256 public constant MAX_SUPPLY = 2696 - RESERVE_SUPPLY;

	SaleState public saleState = SaleState.None;

	uint256 public publicSalePrice = 0.0069 ether;
	uint256 public privateSalePrice = 0.003 ether;

	uint256 public maxPublicMintPerAddress = 5;
	uint256 public maxPrivateMintPerAddress = 2;

	uint256 public totalPrivateMinted = 0;
	uint256 public totalReserveMinted = 0;

	string public baseURI =
		"ipfs://bafybeidkryzfk5nwd5bhtu43lt6j6p5tsytjvwsfbxu7xd2bn7zlaufmyq/";
	string public baseURISuffix = ".json";

	bytes32 private merkleRoot =
		0xa086fbdef2efa23778a56b700af618f0b0815393f68befe66d58c381b75e6054;

	mapping(address => uint256) private publicMints;
	mapping(address => uint256) private privateMints;

	constructor() ERC721A("Hooters", "HOOTERS") {}

	modifier validateMint(uint256 _amount) {
		require(_amount > 0, "Invalid mint amount!");
		require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
		_;
	}

	function mint(uint256 _amount) external payable validateMint(_amount) {
		require(saleState == SaleState.Public, "Public sale not started.");
		require(
			publicMints[msg.sender] + _amount <= maxPublicMintPerAddress,
			"Max mint exceeded."
		);
		require(msg.value >= publicSalePrice * _amount, "Insufficient funds!");

		publicMints[msg.sender] += _amount;
		_mint(msg.sender, _amount);
	}

	function whitelistMint(uint256 _amount, bytes32[] memory _proof)
		external
		payable
		validateMint(_amount)
	{
		require(saleState == SaleState.Private, "Private sale not started.");
		require(merkleRoot != "", "Merkle tree root not set");
		require(
			MerkleProof.verify(
				_proof,
				merkleRoot,
				keccak256(abi.encodePacked(msg.sender))
			),
			"Invalid proof!"
		);
		require(
			privateMints[msg.sender] + _amount <= maxPrivateMintPerAddress,
			"Max mint exceeded"
		);
		require(
			totalPrivateMinted + _amount <= PRIVATE_SALE_SUPPLY,
			"Max supply exceeded!"
		);
		require(msg.value >= privateSalePrice * _amount, "Insufficient funds!");

		privateMints[msg.sender] += _amount;
		totalPrivateMinted += _amount;
		_mint(msg.sender, _amount);
	}

	function setSaleState(SaleState _saleState) external onlyOwner {
		saleState = _saleState;
	}

	function setSaleConfig(
		uint256 _privateSalePrice,
		uint256 _maxPrivateMint,
		uint256 _publicSalePrice,
		uint256 _maxPublicMint
	) external onlyOwner {
		privateSalePrice = _privateSalePrice;
		maxPrivateMintPerAddress = _maxPrivateMint;
		publicSalePrice = _publicSalePrice;
		maxPublicMintPerAddress = _maxPublicMint;
	}

	function setBaseURI(string calldata _uri, string calldata _suffix)
		external
		onlyOwner
	{
		baseURI = _uri;
		baseURISuffix = _suffix;
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(_tokenId),
			"ERC721Metadata: URI query for nonexistent token"
		);

		string memory currentBaseURI = _baseURI();
		return
			bytes(currentBaseURI).length > 0
				? string(
					abi.encodePacked(
						currentBaseURI,
						_toString(_tokenId),
						baseURISuffix
					)
				)
				: "";
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		merkleRoot = _root;
	}

	function airdrop(address[] memory addresses, uint256 amount)
		external
		onlyOwner
	{
		require(
			totalReserveMinted.add(addresses.length.mul(amount)) <=
				RESERVE_SUPPLY,
			"Insufficient reserve."
		);

		for (uint256 i = 0; i < addresses.length; i++) {
			_mint(addresses[i], amount);
		}

		totalReserveMinted = totalReserveMinted.add(
			addresses.length.mul(amount)
		);
	}

	function withdraw() external onlyOwner {
		(bool w1, ) = payable(0xDe6216745EdB960E5449783a8e0F19C4cc5d0487).call{
			value: (address(this).balance * 7) / 100
		}("");
		require(w1);

		(bool w2, ) = payable(owner()).call{ value: address(this).balance }("");
		require(w2);
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
}