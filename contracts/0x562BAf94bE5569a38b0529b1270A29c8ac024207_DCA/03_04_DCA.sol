// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { ISwapRouter } from "src/interfaces/ISwapRouter.sol";

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

interface IQuoter {
  function quoteExactInputSingle(
    address tokenIn,
    address tokenOut,
    uint24 fee,
    uint256 amountIn,
    uint160 sqrtPriceLimitX96
  ) external returns (uint256 amountOut);
}

contract DCA is Ownable {
  uint256 public batchAmount;
  address public immutable funder;
  address public immutable receiver;
  address public immutable usdc;
  address public immutable weth;
  address public immutable swapRouter;
  uint24 public constant poolFee = 500;

  constructor(
    address _swapRouter,
    address _funder,
    address _receiver,
    address _usdc,
    address _weth,
    uint256 _batchAmount
  ) {
    swapRouter = _swapRouter;
    funder = _funder;
    receiver = _receiver;
    usdc = _usdc;
    weth = _weth;
    batchAmount = _batchAmount;
    IERC20(usdc).approve(swapRouter, type(uint256).max);
  }

  function adjust(uint256 _batchAmount) external onlyOwner {
    require(_batchAmount > 0, "DCA: _batchAmount cannot be zero");
    batchAmount = _batchAmount;
  }

  function execute(uint256 amountOutMinimum) external onlyOwner returns (uint256) {
    IERC20(usdc).transferFrom(funder, address(this), batchAmount);
    ISwapRouter.ExactInputSingleParams memory swapParams;
    swapParams.tokenIn = usdc;
    swapParams.tokenOut = weth;
    swapParams.fee = poolFee;
    swapParams.recipient = receiver;
    swapParams.deadline = block.timestamp;
    swapParams.amountIn = batchAmount;
    swapParams.amountOutMinimum = amountOutMinimum;
    return ISwapRouter(swapRouter).exactInputSingle(swapParams);
  }

  function getAmountOut(address quoter) external returns (uint256 amountOut) {
    amountOut = IQuoter(quoter).quoteExactInputSingle(usdc, weth, poolFee, batchAmount, 0);
  }
}