// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IERC20.sol";
import "../interfaces/IWBNB.sol";
import "../interfaces/IUniswapV2Router01.sol";

contract SwapPancakeRoute1_Main {
  address private owner;
  address private constant WBNB_MAIN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address private constant routerApe = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
  address private constant routerPancake = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  IWBNB wbnb = IWBNB(WBNB_MAIN);
  constructor ( ) public {
    owner = msg.sender;
  }
  receive() external payable {}
  function excuteSwap (address _tokenOut) external {
    require(msg.sender == owner, "not owner");
    IERC20(WBNB_MAIN).approve(routerPancake, wbnb.balanceOf(address(this)));
    address[] memory path;
    address[] memory path_;
    path = new address[](2);
    path_ = new address[](2);
    path[0] = WBNB_MAIN;
    path[1] = _tokenOut;
    path_[0] = _tokenOut;
    path_[1] = WBNB_MAIN;
    uint[] memory amounts = IUniswapV2Router01(routerPancake).swapExactTokensForTokens(wbnb.balanceOf(address(this)), 0, path, address(this), block.timestamp);
    IERC20(_tokenOut).approve(routerApe, amounts[1]);
    IUniswapV2Router01(routerApe).swapExactTokensForTokens(amounts[1], 0, path_ , address(this), block.timestamp);
    uint pf_WBNB = wbnb.balanceOf(address(this)) - amounts[0];
    wbnb.withdraw(pf_WBNB);
    payable(msg.sender).transfer(pf_WBNB);
  }

  function withdrawWBNB( ) external {
    require(msg.sender == owner, "not owner");
    wbnb.transfer(msg.sender, wbnb.balanceOf(address(this)));
  }
}