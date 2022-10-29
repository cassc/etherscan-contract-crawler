// SPDX-License-Identifier: MIT
// Created by DegenLabs https://degenlabs.one

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KoolAid is ERC20, Ownable {
	using SafeERC20 for IERC20;

	constructor() ERC20("Kool aid", "$kool") {}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}

	function decimals() public view virtual override returns (uint8) {
		return 9;
	}

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success);
	}
}