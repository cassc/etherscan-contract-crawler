// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "./IBtcPriceOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract BtcPriceOracle is OwnableUpgradeSafe, IBtcPriceOracle {
  using FixedPoint for *;

  uint256 public constant PERIOD = 20 minutes;

  event Price(uint256 price);

  address public immutable weth;
  address public immutable factory;

  // governance params
  address[] public referenceTokens;

  // working memory
  mapping(address => uint256) public priceCumulativeLast;
  uint32 public blockTimestampLast;
  FixedPoint.uq112x112 public priceAverage;

  constructor(
    address _factory,
    address _weth,
    address[] memory tokenizedBtcs
  ) public {
    __Ownable_init();
    factory = _factory;
    weth = _weth;
    for (uint256 i = 0; i < tokenizedBtcs.length; i++) {
      _addPair(tokenizedBtcs[i], _factory, _weth);
    }
  }

  function _addPair(
    address tokenizedBtc,
    address _factory,
    address _weth
  ) internal {
    // check inputs
    require(tokenizedBtc != address(0), "zero token");
    require(priceCumulativeLast[tokenizedBtc] == 0, "already known");

    // check pair
    IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, _weth, tokenizedBtc));
    require(address(pair) != address(0), "no pair");
    uint112 reserve0;
    uint112 reserve1;
    (reserve0, reserve1, ) = pair.getReserves();
    require(reserve0 != 0 && reserve1 != 0, "BtcOracle: NO_RESERVES"); // ensure that there's liquidity in the pair

    // fetch the current accumulated price value (0 / 1)
    priceCumulativeLast[tokenizedBtc] = (pair.token0() == _weth)
      ? pair.price1CumulativeLast()
      : pair.price0CumulativeLast();
    // add to storage
    referenceTokens.push(tokenizedBtc);
  }

  function update() external {
    uint32 blockTimestamp;
    uint224 priceSum = 0;
    for (uint256 i = 0; i < referenceTokens.length; i++) {
      address tokenizedBtc = referenceTokens[i];
      IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, weth, tokenizedBtc));
      uint256 price0Cumulative;
      uint256 price1Cumulative;
      (price0Cumulative, price1Cumulative, blockTimestamp) = UniswapV2OracleLibrary
        .currentCumulativePrices(address(pair));
      uint256 priceCumulative = (pair.token0() == weth) ? price1Cumulative : price0Cumulative;
      uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

      // ensure that at least one full period has passed since the last update
      require(timeElapsed >= PERIOD, "ExampleOracleSimple: PERIOD_NOT_ELAPSED");

      // overflow is desired, casting never truncates
      // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
      uint256 price = (priceCumulative - priceCumulativeLast[tokenizedBtc]) / timeElapsed;
      emit Price(price);
      priceSum += FixedPoint.uq112x112(uint224(price))._x;

      priceCumulativeLast[tokenizedBtc] = priceCumulative;
    }
    // TODO: use weights
    // TODO: use geometric
    priceAverage = FixedPoint.uq112x112(priceSum).div(uint112(referenceTokens.length));
    blockTimestampLast = blockTimestamp;
  }

  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountIn) external override view returns (uint256 amountOut) {
    require(referenceTokens.length > 0, "nothing to track");
    return priceAverage.mul(amountIn / 10**10).decode144();
  }

  // governance functions
  function addPair(address tokenizedBtc) external onlyOwner {
    _addPair(tokenizedBtc, factory, weth);
  }

  function removePair(address tokenizedBtc) external onlyOwner {
    for (uint256 i = 0; i < referenceTokens.length; i++) {
      if (referenceTokens[i] == tokenizedBtc) {
        priceCumulativeLast[tokenizedBtc] = 0;
        referenceTokens[i] = referenceTokens[referenceTokens.length - 1];
        referenceTokens.pop();
        return;
      }
    }
    require(false, "remove not found");
  }
}