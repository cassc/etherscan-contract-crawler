// SPDX-License-Identifier: CC0
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IBlooomCollectionInitializer.sol";

contract BlooomCollectionTemplate is Initializable, IBlooomCollectionInitializer, ERC721A {
	address payable public owner;
	string private _name;
	string private _symbol;

	uint32 public maxSupply = 0;
	uint32 public maxPerWallet = 0;
	uint64 public price = 0.000 ether;
	string public baseURI = "";

	constructor() ERC721A("", "") initializer {
		owner = payable(msg.sender);
		_name = "BlooomCollectionTemplate";
		_symbol = "BCT";
	}

	/**
	 * @notice Called by the factory on creation.
	 * @dev This may only be called once.
	 */
	function initialize(
		address payable creator_,
		string memory name_,
		string memory symbol_,
		uint32 maxSupply_,
		uint32 maxPerWallet_,
		uint64 price_,
		string memory baseURI_
	) external initializer {
		// require(msg.sender == address(collectionFactory), "BlooomCollectionTemplate: Collection must be created via the factory");
		owner = creator_;
		_name = name_;
		_symbol = symbol_;
		maxSupply = maxSupply_;
		maxPerWallet = maxPerWallet_;
		price = price_;
		baseURI = baseURI_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "BlooomCollectionTemplate: Caller is not owner");
		_;
	}

	function withdraw() external payable onlyOwner {
		payable(owner).transfer(address(this).balance);
	}

	////////// ERC721 //////////

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
	}

	function mint(uint256 quantity) external payable {
		require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
		require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Exceeded per wallet limit");
		require(msg.value >= quantity * price, "Incorrect ETH amount");
		// require(tx.origin == _msgSender(), "No contracts");
		_safeMint(msg.sender, quantity);
	}
}