// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TokenInfo.sol";


contract Narwhal {
  using SafeMath for uint256;
  using TokenInfo for bytes32;

  address public immutable uniswapFactory;
  address public immutable sushiswapFactory;
  IWETH public immutable weth;

/** ========== Constructor ========== */

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) {
    uniswapFactory = _uniswapFactory;
    sushiswapFactory = _sushiswapFactory;
    weth = IWETH(_weth);
  }

/** ========== Fallback ========== */

  receive() external payable {
    assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
  }

/** ========== Swaps ========== */

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, bytes32[] memory path, address recipient) internal {
    for (uint i; i < path.length - 1; i++) {
      (bytes32 input, bytes32 output) = (path[i], path[i + 1]);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = (input < output) ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : recipient;
      IUniswapV2Pair(pairFor(input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

/** ========== Pair Calculation & Sorting ========== */

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function zeroForOne(bytes32 tokenA, bytes32 tokenB) internal pure returns (bool) {
    return tokenA < tokenB;
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(bytes32 tokenA, bytes32 tokenB)
    internal
    pure
    returns (bytes32 token0, bytes32 token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != bytes32(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculateUniPair(address token0, address token1 ) internal view returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            uniswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  function calculateSushiPair(address token0, address token1) internal view returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            sushiswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address tokenA,
    address tokenB,
    bool sushi
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = sushi ? calculateSushiPair(token0, token1) : calculateUniPair(token0, token1);
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(bytes32 tokenInfoA, bytes32 tokenInfoB) internal view returns (address pair) {
    (address tokenA, bool sushi) = tokenInfoA.unpack();
    address tokenB = tokenInfoB.readToken();
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = sushi ? calculateSushiPair(token0, token1) : calculateUniPair(token0, token1);
  }

/** ========== Pair Reserves ========== */

  // fetches and sorts the reserves for a pair
  function getReserves(
    bytes32 tokenInfoA,
    bytes32 tokenInfoB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(tokenInfoA, tokenInfoB)).getReserves();
    (reserveA, reserveB) = tokenInfoA < tokenInfoB
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

/** ========== Swap Amounts ========== */

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    bytes32[] memory path,
    uint256 amountIn
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    bytes32[] memory path,
    uint256 amountOut
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}