// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IRewards.sol";
import "../interfaces/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CompoundBootstrap is Ownable {
    using SafeERC20 for IERC20;

    constructor() {
      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
      uniswapV2Router = _uniswapV2Router;
      IRewards _irewards = IRewards(0x6882531E1EE7d90fd6fbc655d9353449E022bdff);
      irewards = _irewards;
      IERC20(WMX).safeApprove(address(uniswapV2Router), type(uint256).max);
      IERC20(WOM).safeApprove(bootstrapAddress, type(uint256).max);
    }
  
  IWETH private WETH;

  IUniswapV2Router02 public uniswapV2Router;
  IRewards public irewards;
  address public constant bootstrapAddress = 0x6882531E1EE7d90fd6fbc655d9353449E022bdff;
  address public constant WMX = 0xa75d9ca2a0a1D547409D82e1B06618EC284A2CeD;
  address public constant WOM = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;
  address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  
function swapWMXforWOM(uint256 wmxAmount) internal {

        address[] memory path = new address[](3);
        path[0] = WMX;
        path[1] = BUSD;
        path[2] = WOM;

        // now we're cookin with WOM!
        uniswapV2Router.swapExactTokensForTokens(
            wmxAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

function compoundWMX() external onlyOwner {
  
  uint256 wmxAmount = IERC20(WMX).balanceOf(msg.sender);
  uint256 womAmount = IERC20(WOM).balanceOf(msg.sender);
  IERC20(WMX).transferFrom(msg.sender, address(this), wmxAmount);
  IERC20(WOM).transferFrom(msg.sender, address(this), womAmount);
  swapWMXforWOM(wmxAmount);
  uint256 amountToStake = IERC20(WOM).balanceOf(address(this));
  irewards.stakeFor(msg.sender, amountToStake);

}

function rescueFunds() external onlyOwner {

  uint256 wmxToSave = IERC20(WMX).balanceOf(address(this));
  uint256 womToSave = IERC20(WOM).balanceOf(address(this));

  IERC20(WMX).transferFrom(address(this), msg.sender, wmxToSave);
  IERC20(WOM).transferFrom(address(this), msg.sender, womToSave);

}

function withdraw() external onlyOwner {

  uint256 wmxToSave = IERC20(WMX).balanceOf(address(this));
  uint256 womToSave = IERC20(WOM).balanceOf(address(this));

  IERC20(WMX).transferFrom(address(this), msg.sender, wmxToSave);
  IERC20(WOM).transferFrom(address(this), msg.sender, womToSave);

}

}