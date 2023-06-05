// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { DefaultOperatorFilterer } from "./libs/DefaultOperatorFilterer.sol";

contract RedPill is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
	using SafeERC20 for IERC20;

	bool public started = false;
	mapping(address => uint256) private minted;
	uint256 private maxOwn = 100;
	string public uri;
	uint256 public constant price = 0.005 ether;

	constructor(string memory _uri) ERC721A("RedPill", "RedPill") {
		uri = _uri;
	}

	function mint(uint256 amount) public payable nonReentrant {
		require(started, "Not started");
		require(msg.sender == tx.origin);
		require(amount > 0, "invalid amount");
		require(minted[msg.sender] + amount <= maxOwn, "Over Limit");
		require(msg.value >= amount * price, "Not enough ether");

		minted[msg.sender] += amount;
		_safeMint(msg.sender, amount);
	}

	function _baseURI() internal view override returns (string memory) {
		return uri;
	}

	function total() public view returns (uint256) {
		return _totalMinted();
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

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override onlyAllowedOperator(from) {
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