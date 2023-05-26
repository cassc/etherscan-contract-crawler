//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Nemesis Bot Contract
/// @dev Contract used to authenticate Nemesis NFT bot and bind the membership to an NFT. Based on ERC721A
/// @author NullRoutes (a.k.a Wang)
contract Nemesis is ERC721A {
	using Strings for uint256;
	using ECDSA for bytes32;

	uint256 public MAX_SUPPLY = 444;
	uint256 public STOCK_AVAILABLE = 0;

	uint256 private _oneMonth = 60 * 60 * 24 * 30;
	uint256 private _gracePeriod = 60 * 60 * 24 * 30;

	mapping(uint256 => uint256) private _tokenExpiry;
	mapping(uint256 => bool) private _usedNonces;

	bool public isPaused = true;

	string baseUri = "https://nemesisautomation.io/metadata/";

	address treasury = 0x3E76049E89E9Cf737A0CA99692AC651FA4ef3F15;
	address API_SIGNER = 0x6495299C449c66B6c4A6f72c8B2fB511772f392b;

	address[] public owners = [0x11c03fa9D9894b7dFF2A5b6D8a764549DfCE0ac4];
	modifier onlyOwner() {
		bool isOwner = false;
		for (uint256 i = 0; i < owners.length; i++) {
			if (msg.sender == owners[i]) {
				isOwner = true;
				break;
			}
		}

		require(isOwner, "Only owner can do this");
		_;
	}

	constructor() ERC721A("Nemesis Bot", "NEMESIS") {}

	/// @dev Mints a new token to the sender at a specific price, after verifying the signature based on price, nonce and sender address.
	function mint(
		uint256 price,
		uint256 nonce,
		bytes memory signature
	) external payable {
		uint256 supply = totalSupply();
		require(!isPaused, "Sale paused");
		require(supply < MAX_SUPPLY, "Maximum supply reached");
		require(STOCK_AVAILABLE > 0, "No stock available");
		require(msg.value >= price, "Not enough ether sent");
		require(!isNonceUsed(nonce), "Nonce already used");

		require(
			isValidPriceSignature(price, nonce, signature),
			"Invalid signature"
		);

		// Invalidate nonce so it can't be reused
		_usedNonces[nonce] = true;

		STOCK_AVAILABLE--;

		// Mint the token and set expiry one month in future
		_safeMint(msg.sender, 1);
		_tokenExpiry[supply] = block.timestamp + _oneMonth;
	}

	/// @dev Renews the token for the sender, after verifying the signature based on token id and sender address. If the grace period has expired, user can't renew anymore.
	function renew(
		uint256 price,
		uint256 nonce,
		bytes memory signature,
		uint256 _tokenId
	) public payable {
		require(ownerOf(_tokenId) == msg.sender, "You don't own that token");
		require(
			_tokenExpiry[_tokenId] + _gracePeriod >= block.timestamp,
			"Token can't be renewed"
		);
		require(msg.value >= price, "Not enough ether sent");
		require(!isNonceUsed(nonce), "Nonce already used");

		require(
			isValidPriceSignature(price, nonce, signature),
			"Invalid signature"
		);

		_usedNonces[nonce] = true;

		// If the token is not expired add one month to the expiry date
		// Otherwise set the expiry date to the current block timestamp and one month
		if (block.timestamp > _tokenExpiry[_tokenId]) {
			_tokenExpiry[_tokenId] = block.timestamp + _oneMonth;
		} else {
			_tokenExpiry[_tokenId] += _oneMonth;
		}
	}

	/// @dev Used for initial airdrop of tokens, easier way of giving all current users NFT
	function airdrop(address[] memory users, bool[] memory isExpiredMap)
		public
		onlyOwner
	{
		require(users.length > 0, "No users provided");
		require(
			users.length == isExpiredMap.length,
			"Users and isExpiredMap must be the same length"
		);
		require(users.length <= MAX_SUPPLY, "Too many users provided");

		uint256 startingIndex = totalSupply();
		uint256 oneMonthInFuture = block.timestamp + _oneMonth;

		// Loop through array
		for (uint256 i = 0; i < users.length; i++) {
			// Mint token to each user
			_safeMint(users[i], 1);

			// If user is expired, set expiry date to current block timestamp
			_tokenExpiry[startingIndex + i] = isExpiredMap[i]
				? block.timestamp
				: oneMonthInFuture;
		}
	}

	/// @dev Used to give NFT in case we miss someone with the airdrop
	function giveToken(address _receiver) public onlyOwner {
		uint256 currentSupply = totalSupply();
		require(currentSupply < MAX_SUPPLY, "Maximum supply reached");

		_safeMint(_receiver, 1);
		_tokenExpiry[totalSupply()] = block.timestamp + _oneMonth;
	}

	function setStockAvailable(uint256 _stock) public onlyOwner {
		STOCK_AVAILABLE = _stock;
	}

	function setGracePeriod(uint256 _newPeriod) public onlyOwner {
		_gracePeriod = _newPeriod;
	}

	function setExpiry(uint256 id, uint256 ts) public onlyOwner {
		_tokenExpiry[id] = ts;
	}

	function setPausedState(bool val) public onlyOwner {
		isPaused = val;
	}

	function getExpiryForToken(uint256 _id) public view returns (uint256) {
		return _tokenExpiry[_id];
	}

	function withdrawAll() public payable onlyOwner {
		require(payable(treasury).send(address(this).balance));
	}

	function isNonceUsed(uint256 nonce) public view returns (bool) {
		return _usedNonces[nonce];
	}

	function isValidPriceSignature(
		uint256 price,
		uint256 nonce,
		bytes memory _signature
	) public view returns (bool) {
		bytes32 messagehash = keccak256(
			abi.encodePacked(msg.sender, price, nonce)
		);
		address signer = messagehash.toEthSignedMessageHash().recover(
			_signature
		);

		return API_SIGNER == signer;
	}

	function setBaseURI(string memory uri) public onlyOwner {
		baseUri = uri;
	}

	function _baseURI() internal view override returns (string memory) {
		return baseUri;
	}
}