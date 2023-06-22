// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { DefaultOperatorFilterer } from "./libs/DefaultOperatorFilterer.sol";

contract StupidFlocks is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet private blacklist;

	bool public started = false;
	mapping(address => uint256) private minted;
	uint256 private maxOwn = 5;
	uint256 private constant maxNFTs = 10000;
	string public uri;
	uint256 public constant price = 0.0069 ether;

	constructor(string memory _uri) ERC721A("StupidFlocks", "StupidFlocks") {
		uri = _uri;
	}

	function mint(uint256 amount) public payable nonReentrant {
		require(started, "Not started");
		require(msg.sender == tx.origin);
		require(amount > 0, "invalid amount");
		require(minted[msg.sender] + amount <= maxOwn, "Over Limit");
		require(msg.value >= amount * price, "Not enough ether");
		require(_totalMinted() + 1 <= maxNFTs, "Mint ended");

		isOnBlacklist();

		minted[msg.sender] += amount;
		_safeMint(msg.sender, amount);
	}

	function _baseURI() internal view override returns (string memory) {
		return uri;
	}

	function total() public view returns (uint256) {
		return _totalMinted();
	}

	function isOnBlacklist() public view {
		uint256 len = EnumerableSet.length(blacklist);
		for (uint256 i = 0; i < len; i++) {
			require(IERC721A(EnumerableSet.at(blacklist, i)).balanceOf(msg.sender) == 0, "BLACKLISTED");
		}
	}

	// OWNER SECTION

	function setURI(string calldata _uri) external onlyOwner {
		uri = _uri;
	}

	function start() external onlyOwner {
		started = true;
	}

	function stop() external onlyOwner {
		started = false;
	}

	function addToBlacklist(address _addr) external onlyOwner {
		EnumerableSet.add(blacklist, _addr);
	}

	function removeFromBlacklist(address _addr) external onlyOwner {
		EnumerableSet.remove(blacklist, _addr);
	}

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}
}