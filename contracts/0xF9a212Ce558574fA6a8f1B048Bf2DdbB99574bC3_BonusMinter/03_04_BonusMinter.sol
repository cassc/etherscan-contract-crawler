// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ICrossmintable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

error BonusMinter__WrongEtherAmmount();
error BonusMinter__NotEnoughTokens();
error BonusMinter__NotEnoughEtherToFundBonusTokens();

/**
 * @title BonusMinter
 * @author DeployLabs.io
 *
 * @dev Contract for minting bonus tokens on Sol3Mates.
 */
contract BonusMinter is Ownable {
	ICrossmintable private i_crossmintable;

	uint16 private s_bonusTokensCount = 1;
	uint256 private s_tokenPrice = 0.03 ether;

	constructor(address crossmintableAddress) {
		i_crossmintable = ICrossmintable(crossmintableAddress);
	}

	receive() external payable {}

	/**
	 * @dev Mint tokens to the specified address imitating crossmint.io and adding bonus tokens.
	 * Bonus tokens are covered by the contract owner.
	 *
	 * @param mintTo The address to mint the token to.
	 * @param quantity The quantity of tokens to mint.
	 */
	function mint(address mintTo, uint16 quantity) external payable {
		if (msg.value != s_tokenPrice * quantity) revert BonusMinter__WrongEtherAmmount();
		if (quantity < 1) revert BonusMinter__NotEnoughTokens();

		uint16 resultingQuantity = quantity + s_bonusTokensCount;
		uint256 resultingPrice = s_tokenPrice * resultingQuantity;
		if (address(this).balance < resultingPrice)
			revert BonusMinter__NotEnoughEtherToFundBonusTokens();

		i_crossmintable.crossmintMint{ value: resultingPrice }(mintTo, resultingQuantity);
	}

	/**
	 * @dev Withdraw all money from the contract.
	 *
	 * @param to The address to withdraw the money to.
	 */
	function withdraw(address payable to) external onlyOwner {
		payable(to).transfer(address(this).balance);
	}

	/**
	 * @dev Set the quantity of bonus tokens to mint.
	 *
	 * @param bonusTokensCount The quantity of bonus tokens to mint.
	 */
	function setBonusTokensCount(uint16 bonusTokensCount) external onlyOwner {
		s_bonusTokensCount = bonusTokensCount;
	}

	/**
	 * @dev Set the price of a token.
	 *
	 * @param tokenPrice The price of a token, specified in wei.
	 */
	function setTokenPrice(uint256 tokenPrice) external onlyOwner {
		s_tokenPrice = tokenPrice;
	}
}