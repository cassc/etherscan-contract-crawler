// SPDX-License-Identifier: MIT
// Created by DegenLabs https://degenlabs.one

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../mocks/ERC721A.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IParentContract {
	function sacrificeFromNextLvl(uint256[] memory tokens, address tokenOwner) external;
}

contract CultOfETHlevel is ERC721A, Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	bool public enabled = false;
	address private previousLevelContract;
	address private nextLevelContract;

	string private URI;
	uint256 public sacrificeAmount;

	constructor(
		address _previousLevelContract,
		string memory _name,
		string memory _symbol,
		string memory _uri,
		uint256 _sacrificeAmount
	) ERC721A(_name, _symbol) {
		URI = _uri;
		sacrificeAmount = _sacrificeAmount;
		previousLevelContract = _previousLevelContract;
	}

	function _baseURI() internal view override returns (string memory) {
		return URI;
	}

	function totalMinted() public view returns (uint256) {
		return _totalMinted();
	}

	function sacrifice(uint256[] memory tokens) external {
		require(enabled, "PAUSED");
		require(tokens.length == sacrificeAmount, "INVALID_TOKENS_AMOUNT");

		for (uint256 i = 0; i < tokens.length; i++) {
			for (uint256 j = 0; j < tokens.length; j++) {
				if (i == j) {
					continue;
				}
				require(tokens[i] != tokens[j], "DUPLICATE");
			}
		}

		IParentContract(previousLevelContract).sacrificeFromNextLvl(tokens, msg.sender);
		_safeMint(msg.sender, 1);
	}

	function sacrificeFromNextLvl(uint256[] memory tokens, address tokenOwner) external {
		require(msg.sender == nextLevelContract, "Lvl: DENIED");
		require(tokens.length > 0, "Lvl: EMPTY");

		for (uint256 i = 0; i < tokens.length; i++) {
			require(ownerOf(tokens[i]) == tokenOwner, "Lvl: NOT_OWNER");
		}

		for (uint256 i = 0; i < tokens.length; i++) {
			_burn(tokens[i]);
		}
	}

	// ONLY OWNER SECTION

	function setPreviousLvlContract(address _previousLevelContract) external onlyOwner {
		previousLevelContract = _previousLevelContract;
	}

	function setNextLvlContract(address _nextLevelContract) external onlyOwner {
		nextLevelContract = _nextLevelContract;
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		URI = newBaseURI;
	}

	function start() external onlyOwner {
		enabled = true;
	}

	function pause() external onlyOwner {
		enabled = false;
	}

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}
}