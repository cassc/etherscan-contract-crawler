// SPDX-License-Identifier: MIT
// Created by DegenLabs https://degenlabs.one

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./mocks/ERC721A.sol";
import "./WhitelistV2.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DorX is ERC721A, Ownable, ReentrancyGuard, WhitelistV2 {
	using SafeERC20 for IERC20;

	bool public mintStarted = false;

	mapping(address => uint256) private minted;

	uint256 private constant maxNFTs = 3333;
	uint256 private maxCanOwn = 1;

	string private URI = "https://api.dorx.wtf/nft/";

	constructor(address signatureChecker) ERC721A("DorX", "DorX") WhitelistV2(signatureChecker) {}

	function mint() public nonReentrant notOnBlacklist {
		require(mintStarted, "Not started");
		require(msg.sender == tx.origin);
		require(minted[msg.sender] + 1 <= maxCanOwn, "Limit reached");
		require(_totalMinted() + 1 <= maxNFTs, "Mint ended");

		minted[msg.sender] += 1;
		_safeMint(msg.sender, 1);
	}

	function mintWhitelist(
		uint256 nonce,
		uint256 amount,
		uint16 maxAmount,
		bytes memory signature
	) public nonReentrant notOnBlacklist {
		require(msg.sender == tx.origin);
		require(amount != 0, "Invalid amount");
		require(_totalMinted() + amount <= maxNFTs, "Amount over the limit");
		require(minted[msg.sender] + amount <= maxAmount, "Over whitelist limit");

		_checkWhitelist(msg.sender, maxAmount, nonce, signature);

		minted[msg.sender] += amount;

		_safeMint(msg.sender, amount);
	}

	function _baseURI() internal view override returns (string memory) {
		return URI;
	}

	function mintedTotal() public view returns (uint256) {
		return _totalMinted();
	}

	function totalMintable() public pure returns (uint256) {
		return maxNFTs;
	}

	// ONLY OWNER SECTION

	function mintOwner(address _oo, uint256 amount) public onlyOwner {
		require(_totalMinted() + amount <= maxNFTs, "Mint ended");
		_safeMint(_oo, amount);
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		URI = newBaseURI;
	}

	function setMaxCanOwn(uint256 _mo) external onlyOwner {
		maxCanOwn = _mo;
	}

	function startMint() external onlyOwner {
		mintStarted = true;
	}

	function pauseMint() external onlyOwner {
		mintStarted = false;
	}

	function startWhiteListMint() external onlyOwner {
		_startWhitelistMint();
	}

	function pauseWhiteListMint() external onlyOwner {
		_pauseWhitelistMint();
	}

	function removeFromWhiteList(uint256 nonce) external onlyOwner {
		_removeFromWhitelist(nonce);
	}

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}
}