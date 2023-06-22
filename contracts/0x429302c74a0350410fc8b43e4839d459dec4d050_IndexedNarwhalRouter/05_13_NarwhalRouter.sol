// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Narwhal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";


contract NarwhalRouter is Narwhal {
  using TokenInfo for bytes32;
  using TokenInfo for address;
  using TransferHelper for address;
  using SafeMath for uint256;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "NRouter: EXPIRED");
    _;
  }

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) Narwhal(_uniswapFactory, _sushiswapFactory, _weth) {}

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = getAmountsOut(path, amountIn);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsOut(path, msg.value);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsOut(path, amountIn);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= msg.value, "NRouter: MAX_IN");
    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
    // // refund dust eth, if any
    if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
  }
}