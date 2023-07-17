// SPDX-License-Identifier: MIT
// Created by DegenLabs https://degenlabs.one

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../mocks/ERC721A.sol";
import "../WhitelistV2.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CultOfETH is ERC721A, Ownable, ReentrancyGuard, WhitelistV2 {
	using SafeERC20 for IERC20;

	bool public mintStarted = false;

	mapping(address => uint256) private minted;
	address private nextLevelContract;

	uint256 public maxNFTs;
	uint256 public maxCanOwn;

	string private URI;

	event NewLevelAdded(address indexed token);

	constructor(
		address signatureChecker,
		string memory _name,
		string memory _symbol,
		string memory _uri,
		uint256 _maxCanOwn,
		uint256 _maxNFTs
	) ERC721A(_name, _symbol) WhitelistV2(signatureChecker) {
		maxCanOwn = _maxCanOwn;
		maxNFTs = _maxNFTs;
		URI = _uri;
	}

	function mint(uint256 amount) public nonReentrant notOnBlacklist {
		require(mintStarted, "Not started");
		require(msg.sender == tx.origin, "Direct only");
		require(minted[msg.sender] + amount <= maxCanOwn, "Limit reached");
		require(_totalMinted() + amount <= maxNFTs, "Mint ended");

		minted[msg.sender] += amount;
		_safeMint(msg.sender, amount);
	}

	function mintWhitelist(
		uint256 nonce,
		uint256 amount,
		uint16 maxAmount,
		bytes memory signature
	) public nonReentrant notOnBlacklist {
		require(msg.sender == tx.origin, "Direct only");
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

	function totalMinted() public view returns (uint256) {
		return _totalMinted();
	}

	function totalMintable() public view returns (uint256) {
		return maxNFTs;
	}

	function sacrificeFromNextLvl(uint256[] memory tokens, address tokenOwner) external {
		require(msg.sender == nextLevelContract, "CultFather: DENIED");
		require(tokens.length > 0, "CultFather: EMPTY");

		for (uint256 i = 0; i < tokens.length; i++) {
			require(ownerOf(tokens[i]) == tokenOwner, "CultFather: NOT_OWNER");
		}

		for (uint256 i = 0; i < tokens.length; i++) {
			_burn(tokens[i]);
		}
	}

	// ONLY OWNER SECTION

	function mintOwner(address _oo, uint256 amount) public onlyOwner {
		require(_totalMinted() + amount <= maxNFTs, "Mint ended");
		_safeMint(_oo, amount);
	}

	function setNextLevelContract(address _nextLevelContract) external onlyOwner {
		nextLevelContract = _nextLevelContract;
	}

	function addNewLevel(address _newLevel) external onlyOwner {
		emit NewLevelAdded(_newLevel);
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