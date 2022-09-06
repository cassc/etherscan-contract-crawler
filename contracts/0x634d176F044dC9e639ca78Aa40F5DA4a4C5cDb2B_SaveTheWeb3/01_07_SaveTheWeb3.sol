//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SaveTheWeb3 is Ownable, ERC721A, ReentrancyGuard {
	uint256 public immutable collectionSize;

	uint256 public maxPerAddressDuringMint;
	uint256 public maxWhitelistMintCount;

	// whitelist root
	bytes32 public whitelistRoot;

	uint64 public whitelistPrice;
	uint64 public publicPrice;

	uint256 public whitelistSaleStartTime;
	uint256 public whitelistSaleEndTime;

	uint256 public publicSaleStartTime;
	uint256 public publicSaleEndTime;

	string private _baseTokenURI;

	mapping(address => uint8) public whitelistMinted;

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "the caller is another contract");
		_;
	}

	constructor(uint256 maxBatchSize_, uint256 collectionSize_) ERC721A("SaveTheWeb3", "SAV3") {
		maxPerAddressDuringMint = maxBatchSize_;
		collectionSize = collectionSize_;
		maxWhitelistMintCount = 5;
	}

	function whitelistMint(uint8 quantity, bytes32[] memory proof) external payable callerIsUser {
		uint256 price = whitelistPrice * quantity;
		require(price != 0 && isWhitelistSaleOn(), "whitelist sale has not begun yet");
		require(isValidWhitelist(proof, keccak256(abi.encodePacked(msg.sender))), "not eligible for whitelist mint");
		require(totalSupply() + quantity <= collectionSize, "reached max supply");
		require(
			whitelistMinted[msg.sender] + quantity <= maxWhitelistMintCount,
			"reached max mint count for whitelist"
		);

		whitelistMinted[msg.sender] += quantity;
		_safeMint(msg.sender, quantity);
		refundIfOver(price);
	}

	function publicMint(uint8 quantity) external payable callerIsUser {
		uint256 price = publicPrice * quantity;
		require(price != 0 && isPublicSaleOn(), "public sale has not started yet");
		require(totalSupply() + quantity <= collectionSize, "reached max supply");
		require(quantity <= maxPerAddressDuringMint, "can not mint this many");

		_safeMint(msg.sender, quantity);
		refundIfOver(price);
	}

	function refundIfOver(uint256 price) private {
		require(msg.value >= price, "need to send more ETH.");
		if (msg.value > price) {
			payable(msg.sender).transfer(msg.value - price);
		}
	}

	function setWhitelistPrice(uint64 price_) external onlyOwner {
		whitelistPrice = price_;
	}

	function setPublicPrice(uint64 price_) external onlyOwner {
		publicPrice = price_;
	}

	function withdrawMoney() external onlyOwner nonReentrant {
		(bool success, ) = msg.sender.call{ value: address(this).balance }("");
		require(success, "Transfer failed.");
	}

	function numberMinted(address owner) public view returns (uint256) {
		return _numberMinted(owner);
	}

	function ownershipOf(uint256 tokenId) external view returns (TokenOwnership memory) {
		return _ownershipOf(tokenId);
	}

	function isValidWhitelist(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
		return MerkleProof.verify(proof, whitelistRoot, leaf);
	}

	function setWhitelistMerkleRoot(bytes32 root_) external onlyOwner {
		whitelistRoot = root_;
	}

	function isWhitelistSaleOn() public view returns (bool) {
		return whitelistSaleStartTime <= block.timestamp && block.timestamp <= whitelistSaleEndTime;
	}

	function isPublicSaleOn() public view returns (bool) {
		return publicSaleStartTime <= block.timestamp && block.timestamp <= publicSaleEndTime;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string calldata baseURI) external onlyOwner {
		_baseTokenURI = baseURI;
	}

	function setMaxWhitelistMintCount(uint256 count) external onlyOwner {
		maxWhitelistMintCount = count;
	}

	function setMaxPerAddressDuringMint(uint256 count) external onlyOwner {
		maxPerAddressDuringMint = count;
	}

	function getWhitelistSaleTime() public view returns (uint256, uint256) {
		return (whitelistSaleStartTime, whitelistSaleEndTime);
	}

	function setWhitelistSaleTime(uint256 start, uint256 end) external onlyOwner {
		whitelistSaleStartTime = start;
		whitelistSaleEndTime = end;
	}

	function getPublicSaleTime() public view returns (uint256, uint256) {
		return (publicSaleStartTime, publicSaleEndTime);
	}

	function setPublicSaleTime(uint256 start, uint256 end) external onlyOwner {
		publicSaleStartTime = start;
		publicSaleEndTime = end;
	}

	function devMint(uint256 quantity, address addr) external onlyOwner {
		require(totalSupply() + quantity <= collectionSize, "reached max supply");
		_safeMint(addr, quantity);
	}
}