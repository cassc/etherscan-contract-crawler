// SPDX-License-Identifier: MIT
// Created by DegenLabs https://degenlabs.one

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./mocks/ERC721A.sol";
import "./Whitelist.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PiratesOfEth is ERC721A, Ownable, ReentrancyGuard, Whitelist {
	using SafeERC20 for IERC20;

	bool public mintStarted = false;

	mapping(address => uint256) private minted;

	uint256 private constant maxNFTs = 10000;
	uint256 public mintPrice = 0.02 ether;
	uint256 private maxCanOwn = 1;
	uint16 private batchSize = 1;

	string private URI = "https://api.piratesofeth.com/nft/";

	constructor(address signatureChecker) ERC721A("Pirates Of ETH", "PETH") Whitelist(signatureChecker) {}

	function mint() public payable nonReentrant notOnBlacklist {
		require(mintStarted, "Not started");
		require(msg.sender == tx.origin);
		require(minted[msg.sender] + batchSize <= maxCanOwn, "limit reached");
		require(msg.value >= mintPrice * batchSize, "Not enough ether");
		require(_totalMinted() + batchSize <= maxNFTs, "Mint ended");

		minted[msg.sender] += batchSize;
		_safeMint(msg.sender, batchSize);
	}

	function mintWhitelist(
		uint256 nonce,
		uint16 amount,
		bytes memory signature
	) public payable nonReentrant notOnBlacklist {
		require(msg.sender == tx.origin);
		require(amount != 0, "Invalid amount");
		require(msg.value >= mintPrice * amount, "Not enough ether");
		require(_totalMinted() + amount <= maxNFTs, "Amount over the limit");

		_updateWhitelist(msg.sender, amount, nonce, signature);

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

	function setBatchSize(uint16 _bs) external onlyOwner {
		batchSize = _bs;
	}

	function setMintPrice(uint256 _mp) external onlyOwner {
		mintPrice = _mp;
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