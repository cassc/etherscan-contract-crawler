// SPDX-License-Identifier: UNLICENSED
// Created by BondSwap https://bondswap.org

pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);
}

interface IERC20 {
	function decimals() external view returns (uint8);
}

contract BondSwapPriceHelper is Ownable {
	uint256 public rplcPriceInUSD;
	AggregatorV3Interface internal priceFeed;

	constructor(address _priceFeed) {
		priceFeed = AggregatorV3Interface(_priceFeed);
	}

	function getRewardAmountForToken(
		address bondToken,
		address bondPayToken,
		uint256 amountIn
	) public view returns (uint256) {
		// prettier-ignore
		(
            /* uint80 roundID */,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

		console.log("price", uint256(price));

		uint8 feedDec = priceFeed.decimals();
		uint8 rewardTokenDec = IERC20(bondToken).decimals();

		console.log("scale1", scalePrice(rplcPriceInUSD, rewardTokenDec, rewardTokenDec));
		console.log("scale2", scalePrice(uint256(price), feedDec, rewardTokenDec));
		uint256 basePrice = scalePrice(rplcPriceInUSD, rewardTokenDec, rewardTokenDec);
		uint256 quotePrice = scalePrice(uint256(price), feedDec, rewardTokenDec);
		console.log("first1", (basePrice * 10**rewardTokenDec));
		console.log("result", (basePrice * 10**rewardTokenDec) / quotePrice);

		return amountIn * ((basePrice * 10**rewardTokenDec) / quotePrice);
	}

	function scalePrice(
		uint256 _price,
		uint8 _priceDecimals,
		uint8 _decimals
	) internal pure returns (uint256) {
		if (_priceDecimals < _decimals) {
			return _price * uint256(10**uint256(_decimals - _priceDecimals));
		} else if (_priceDecimals > _decimals) {
			return _price / uint256(10**uint256(_priceDecimals - _decimals));
		}
		return _price;
	}

	function setTokenPriceInUSD(uint256 _price) external onlyOwner {
		rplcPriceInUSD = _price;
	}
}