//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PriceCalculator {
    using SafeMath for uint256;

    IUniswapV2Router02 public router;

    address bnb;
    address usdt;

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        bnb = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        usdt = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    function getLatestPrice(address _tokenAddress, uint256 _tokenAmount)
        public
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = bnb;

        // get token price in bnb
        uint256[] memory amounts = router.getAmountsOut(_tokenAmount, path);

        uint256 bnbAmount = amounts[1];
        uint256 tokenPriceInUsdt = getBnbPrice(bnbAmount);

        return tokenPriceInUsdt;
    }

    function getBnbPrice(uint256 _amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = bnb;
        path[1] = usdt;

        uint256[] memory amounts = router.getAmountsOut(_amount, path);

        return amounts[1];
    }
}