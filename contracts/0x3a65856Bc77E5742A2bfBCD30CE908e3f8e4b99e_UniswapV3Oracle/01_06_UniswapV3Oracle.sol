// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {FullMath} from '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import {IERC20Metadata} from "./interfaces/IERC20Metadata.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IUniswapV3Twap} from "./interfaces/IUniswapV3Twap.sol";
import {IPriceGetter} from "./interfaces/IPriceGetter.sol";

contract UniswapV3Oracle is IPriceGetter {
  IERC20Metadata public immutable token;
  IUniswapV3Twap public immutable twap;
  AggregatorV3Interface public immutable aggregator;

  constructor(address _token, address _twap, address _aggregator) {
    require(_twap != address(0), '!twap');
    twap = IUniswapV3Twap(_twap);
    token = IERC20Metadata(_token);
    aggregator = AggregatorV3Interface(_aggregator);
  }

  function getPrice() external view override returns (uint256 price) {
    (uint amountOut, uint8 decimalsOut) = twap.estimateAmountOut(address(token), uint128(10 ** token.decimals()), 120);
    (, int256 answer,,,) = aggregator.latestRoundData();
    price = FullMath.mulDiv(amountOut, uint256(answer), 10 ** decimalsOut);
  }
}