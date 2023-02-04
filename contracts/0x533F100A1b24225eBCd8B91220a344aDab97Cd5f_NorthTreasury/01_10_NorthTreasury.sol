// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol";

contract NorthTreasury is Ownable {
  address private immutable _weth;

  address public immutable router;

  address private _token;

  event SetToken(address token);
  event ProvideLiquidity(uint256 weth);

  constructor() {
    router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    _weth = IUniswapV2Router02(router).WETH();
  }

  receive() external payable {}

  function setToken(address token) external onlyOwner {
    require(_token == address(0), "NorthTreasury::setToken: token already set");
    _token = token;
    emit SetToken(token);
  }

  function wrappedBalance() external view returns (uint256) {
    return address(this).balance + IERC20(_weth).balanceOf(address(this));
  }

  function wrap() external {
    IWETH(_weth).deposit{ value: address(this).balance }();
  }

  function transfer(address token, address to, uint256 value) external onlyOwner {
    require(token != _token, "NorthTreasury::transfer: North Coin cannot be transfered");
    SafeERC20.safeTransfer(IERC20(token), to, value);
  }

  function provideLiquidity(uint256 weth) external onlyOwner {
    IUniswapV2Router02 uniRouter = IUniswapV2Router02(router);
    require(IERC20(IUniswapV2Factory(uniRouter.factory()).getPair(_token, _weth)).totalSupply() == 0, "NorthTreasury::provideLiquidity: liquidity already provided");
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    token.approve(router, balance);
    IERC20(_weth).approve(router, weth);
    uniRouter.addLiquidity(_token, _weth, balance, weth, 0, 0, _token, block.timestamp);
    emit ProvideLiquidity(weth);
  }
}