// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/ISwapRouter.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MrLiquidity is Ownable  {
  IERC20 public MR;

  ISwapRouter public router = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public TAddress = 0x6967299e9F3d5312740Aa61dEe6E9ea658958e31;
  address public burnAddress = 0xdEAD000000000000000042069420694206942069;

  IERC20 public T = IERC20(TAddress);

  function setMr(address _address) public onlyOwner {
    if (address(MR) == address(0)) {
      MR = IERC20(_address);
      approveRouterSpending();
    }
  }

  function addLiquidity() external {
    require(msg.sender == address(MR), "can only be called from MR");

    // add the liquidity
    router.addLiquidity(
      address(MR),
      TAddress,
      MR.balanceOf(address(this)),
      T.balanceOf(address(this)),
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      burnAddress,
      block.timestamp
    );
  }

  function approveRouterSpending() internal {
    MR.approve(address(router), type(uint256).max);
    T.approve(address(router), type(uint256).max);
  }
}