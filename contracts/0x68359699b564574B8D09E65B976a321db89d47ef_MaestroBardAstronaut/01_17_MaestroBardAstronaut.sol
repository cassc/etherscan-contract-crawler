// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC4906.sol";

contract MaestroBardAstronaut is ERC721, Ownable, IERC4906 {
	using Counters for Counters.Counter;
	using Strings for uint256;

	string private _baseTokenURI = "";
	string private constant _defaultTokenURI = "ipfs://QmbsPwrqtrJoQtegtvc7SaidVQqNMEJxEE66GR6GRwHFdc";
	bytes32 public whitelistMerkleRoot = "";

	Counters.Counter private _currentTokenId;
	uint256 public constant RESERVE = 50;
	uint256 public totalSupply = 1_000;

	bool public saleStart = false;
	mapping(address => bool) private _minted;

	constructor() ERC721("MaestroBardAstronaut", "MBA") {}

	function setWhitelistMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
		whitelistMerkleRoot = newMerkleRoot;
	}

	function whiteMint(bytes32[] memory proof, uint256 timestamp) public returns (uint256) {
		require(saleStart, "Sales haven't started.");
		require(block.timestamp >= timestamp, "Minting process has not started.");
		require(
			MerkleProof.verify(
				proof,
				whitelistMerkleRoot,
				keccak256(abi.encodePacked(msg.sender, timestamp))
			),
			"Minting validation process has failed."
		);
		require(_minted[msg.sender] == false, "Minting process already completed.");

		uint256 id = _mintTo(msg.sender);
		_minted[msg.sender] = true;

		return id;
	}

	function reserveMint() external onlyOwner returns (uint256[] memory) {
		uint256[] memory ids = new uint256[](RESERVE);
		for (uint256 i = 1; i <= RESERVE; i++){
			ids[i - 1] = _mintTo(owner());
		}

		return ids;
	}

	function _mintTo(address recipient) internal returns (uint256) {
		require(_currentTokenId.current() < totalSupply, "Maximum supply already reached.");
		_currentTokenId.increment();
		uint256 newItemId = _currentTokenId.current();

		_safeMint(recipient, newItemId);

		return newItemId;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "Invalid token query.");

		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : _defaultTokenURI;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string calldata uri) external onlyOwner {
		_baseTokenURI = uri;

		uint256 current = _currentTokenId.current();
		if (current > 0) {
			emit BatchMetadataUpdate(1, current);
		}
	}

	function cutSupply() external onlyOwner {
		totalSupply = _currentTokenId.current();
	}

	function numTokens() public view virtual returns (uint256) {
		return _currentTokenId.current();
	}

	function hasMinted(address recipient) public view virtual returns (bool) {
		return _minted[recipient];
	}

	function changeSale() external onlyOwner {
		saleStart = !saleStart;
	}
}