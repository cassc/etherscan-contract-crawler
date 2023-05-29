// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './ERC721A.sol';

// SuperstarTiger has 2 sale stage:
//   1. Public Aution Sale - 2 ether ~ 1 ether (drop 0.25 ether every 5 minutes)
//   2. Whitelist Sale     - 0.88 ether
contract SuperstarTiger is ERC721A, Ownable {
	using Strings for uint256;

	// constants
	uint256 public constant MAX_SUPPLY = 444;

	uint256 public constant WHITELIST_MINT_PRICE = 0.88 ether;

	uint256 public constant AUCTION_MAX_PER_MINT = 2;
	uint256 public constant AUCTION_START_PRICE = 2 ether;
	uint256 public constant AUCTION_END_PRICE = 1 ether;
	uint256 public constant AUCTION_DROP_DURATION = 20 minutes;
	uint256 public constant AUCTION_DROP_INTERVAL = 5 minutes;
	uint256 public constant AUCTION_DROP_PER_STEP =
		(AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_DROP_DURATION / AUCTION_DROP_INTERVAL);

	// global
	bool public saleActivated;
	string private _baseMetaURI;

	// aution sale
	uint256 public auctionSaleStartTime;
	uint256 public auctionSaleEndTime;
	uint256 public auctionSaleMaxSupply;

	// whitelist sale
	uint256 public whitelistSaleStartTime;
	uint256 public whitelistSaleEndTime;
	bytes32 private _whitelistSaleMerkleRoot;
	mapping(address => uint256) private _whitelistSaleWallets;

	constructor() ERC721A('Superstar Tiger', 'TIGER') {}

	modifier callerIsUser() {
		require(tx.origin == msg.sender, 'caller should not be a contract');
		_;
	}

	function whitelistSale(
		bytes32[] memory proof,
		uint256 maxQuantity,
		uint256 quantity
	) external payable callerIsUser {
		require(
			saleActivated &&
				block.timestamp >= whitelistSaleStartTime &&
				block.timestamp <= whitelistSaleEndTime,
			'not on sale'
		);
		require(
			_isWhitelisted(_whitelistSaleMerkleRoot, proof, msg.sender, maxQuantity),
			'not in whitelist'
		);
		require(quantity > 0, 'quantity of tokens cannot be less than or equal to 0');
		require(
			totalSupply() + quantity <= MAX_SUPPLY,
			'the purchase would exceed max supply of tokens'
		);
		require(msg.value >= WHITELIST_MINT_PRICE * quantity, 'insufficient ether value');
		require(
			_whitelistSaleWallets[msg.sender] + quantity <= maxQuantity,
			'quantity of tokens cannot exceed max mint'
		);

		_whitelistSaleWallets[msg.sender] += quantity;
		_safeMint(msg.sender, quantity);
	}

	function auctionSale(uint256 quantity) external payable callerIsUser {
		require(
			saleActivated &&
				block.timestamp >= auctionSaleStartTime &&
				block.timestamp <= auctionSaleEndTime,
			'not on sale'
		);
		require(quantity > 0, 'quantity of tokens cannot be less than or equal to 0');
		require(quantity <= AUCTION_MAX_PER_MINT, 'the purchase would exceed max supply per mint');
		require(
			totalSupply() + quantity <= auctionSaleMaxSupply,
			'the purchase would exceed max supply of current stage'
		);
		require(
			totalSupply() + quantity <= MAX_SUPPLY,
			'the purchase would exceed max supply of tokens'
		);
		require(msg.value >= getAuctionPrice() * quantity, 'insufficient ether value');

		_safeMint(msg.sender, quantity);
	}

	function getAuctionPrice() public view returns (uint256) {
		if (block.timestamp <= auctionSaleStartTime) {
			return AUCTION_START_PRICE;
		}
		if (block.timestamp - auctionSaleStartTime >= AUCTION_DROP_DURATION) {
			return AUCTION_END_PRICE;
		}
		uint256 steps = (block.timestamp - auctionSaleStartTime) / AUCTION_DROP_INTERVAL;
		return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
	}

	function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
		require(_exists(tokenID), 'ERC721Metadata: URI query for nonexistent token');
		string memory base = _baseURI();
		require(bytes(base).length > 0, 'baseURI not set');
		return string(abi.encodePacked(base, tokenID.toString()));
	}

	function batchTransfer(address[] memory addrs, uint256[] memory tokenIDs) public {
		require(addrs.length == tokenIDs.length, 'invalid mapping of addresses and token ids');
		for (uint256 i = 0; i < addrs.length; i++) {
			address to = addrs[i];
			uint256 tokenID = tokenIDs[i];
			transferFrom(msg.sender, to, tokenID);
		}
	}

	/* ****************** */
	/* INTERNAL FUNCTIONS */
	/* ****************** */

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseMetaURI;
	}

	function _isWhitelisted(
		bytes32 root,
		bytes32[] memory proof,
		address account,
		uint256 quantity
	) internal pure returns (bool) {
		return
			MerkleProof.verify(
				proof,
				root,
				keccak256(abi.encodePacked(address(account), uint256(quantity)))
			);
	}

	/* *************** */
	/* ADMIN FUNCTIONS */
	/* *************** */

	function setBaseURI(string memory baseURI) external onlyOwner {
		_baseMetaURI = baseURI;
	}

	function setSaleActivated(bool active) external onlyOwner {
		saleActivated = active;
	}

	function setAuctionSaleTime(uint256 start, uint256 end) external onlyOwner {
		auctionSaleStartTime = start;
		auctionSaleEndTime = end;
	}

	function setAuctionSaleMaxSupply(uint256 maxSupply) external onlyOwner {
		auctionSaleMaxSupply = maxSupply;
	}

	function setWhitelistSaleTime(uint256 start, uint256 end) external onlyOwner {
		whitelistSaleStartTime = start;
		whitelistSaleEndTime = end;
	}

	function setWhitelistSaleMerkleRoot(bytes32 root) external onlyOwner {
		_whitelistSaleMerkleRoot = root;
	}

	function preserve(address to, uint256 quantity) external onlyOwner {
		require(
			totalSupply() + quantity <= MAX_SUPPLY,
			'the purchase would exceed max supply of tokens'
		);
		_safeMint(to, quantity);
	}

	function withdraw(address payable to) external onlyOwner {
		(bool success, ) = to.call{value: address(this).balance}('');
		require(success, 'failed to transfer ether');
	}
}