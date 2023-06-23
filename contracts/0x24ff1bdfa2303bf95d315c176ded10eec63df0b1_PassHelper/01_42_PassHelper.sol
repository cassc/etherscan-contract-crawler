// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "GenesisPass.sol";
import "GenesisMint.sol";
import "DiamondsUps.sol";

contract PassHelper {

	GenesisPass immutable public PASS;
	DiamondsUps immutable public DIAMONDS;

	constructor(address _pass, address _diamonds) {
		PASS = GenesisPass(_pass);
		DIAMONDS = DiamondsUps(_diamonds);
	}

	function getData() external view returns(
		uint256 mintedFromMerkle,
		uint256 mintedFromDiamond,
		uint256 maxSupply,
		uint256 price,
		bool whitelistMint,
		bool publicMint,
		uint256 maxStage,
		uint256 passPrio,
		uint256 diamondPrio,
		uint256 diamondSupply,
		uint256 diamondMintedAmount,
		uint256 diamondMaxMintable,
		uint256[] memory diamondDist) {
		mintedFromMerkle = 69;
		mintedFromDiamond = DIAMONDS.passMinted();
		maxSupply = 777;
		price = 69;
		whitelistMint = false;
		maxStage = DIAMONDS.growthStages();
		passPrio = 69;
		publicMint = passPrio >= 10;
		diamondPrio = DIAMONDS.currentPrio();
		diamondSupply = DIAMONDS.MAX_MINTABLE();
		diamondMintedAmount = DIAMONDS.counter();
		diamondMaxMintable = DIAMONDS.MAX_AMOUNT();
		diamondDist = new uint256[](DIAMONDS.growthStages());
		for (uint256 i = 0; i < DIAMONDS.growthStages(); i++)
			diamondDist[i] = DIAMONDS.diamondStagesCounts(i + 1);
	}

	function priceEachStage() external view returns(
		uint256[] memory prices,
		uint256[] memory pricesEth
	) {
		prices = new uint256[](DIAMONDS.growthStages());
		pricesEth = new uint256[](DIAMONDS.growthStages());
		for (uint256 i = 0; i < DIAMONDS.growthStages(); i++) {
			prices[i] = DIAMONDS.stagePrice(i + 1);
			pricesEth[i] = DIAMONDS.getEURPriceInEth(prices[i]);
		}
	}
}