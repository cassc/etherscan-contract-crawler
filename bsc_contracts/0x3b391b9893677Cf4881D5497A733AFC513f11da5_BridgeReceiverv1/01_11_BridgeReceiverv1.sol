// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import "./../interface/bridge/ILiquidCryptoBridge_v2.sol";
import "./../interface/IUniswapRouterETH.sol";
import "./../interface/IWETH.sol";

contract BridgeReceiverv1 is Ownable {
  using SafeERC20 for IERC20;
  
  address public bridge;

  mapping (address => bool) public managers;

  constructor(address _bridge) {
    bridge = _bridge;

    managers[msg.sender] = true;
    managers[0x5e1f49A1349dd35FACA241eB192c6c2EDF47EF46] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  receive() external payable {
  }

  function redeemStargate(address account, address token, uint256 amount, uint256 fee, address unirouter, address[] memory path) public onlyManager {
    require(IERC20(token).balanceOf(address(this)) >= amount, "BridgeReceiverv1: redeem not completed");
    if (fee > 0) {
      uint256[] memory reqamounts = IUniswapRouterETH(unirouter).getAmountsIn(fee, path);
      uint256 reqAmount = reqamounts[0];
      if (amount > reqAmount) {
        amount -= reqAmount;
      }
      else {
        reqAmount = amount;
        amount = 0;
      }
      _approveTokenIfNeeded(token, unirouter);
      uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(reqAmount, 0, path, address(this), block.timestamp);
      _removeAllowances(token, unirouter);
      uint256 nativeBalance = amounts[amounts.length - 1];
      IWETH(path[path.length-1]).withdraw(nativeBalance);

      (bool success, ) = msg.sender.call{value: nativeBalance}("");
      require(success, "BridgeReceiverv1: send fee");
    }

    if (amount > 0) {
      IERC20(token).safeTransfer(account, amount);
    }
  }

  function redeemStargateAndSwap(address account, address token, uint256 amount, uint256 fee, address unirouter, address[] memory path) public onlyManager {
    require(IERC20(token).balanceOf(address(this)) >= amount, "BridgeReceiverv1: redeem not completed");
    _approveTokenIfNeeded(token, unirouter);
    uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    _removeAllowances(token, unirouter);
    uint256 nativeBalance = amounts[amounts.length - 1];
    IWETH(path[path.length-1]).withdraw(nativeBalance);

    if (nativeBalance > fee) {
      (bool success, ) = payable(account).call{value: nativeBalance - fee}("");
      require(success, "BridgeReceiverv1: redeem");
    }

    if (fee > 0) {
      if (nativeBalance > fee) {
        (bool success, ) = msg.sender.call{value: fee}("");
        require(success, "BridgeReceiverv1: send fee");
      }
      else {
        (bool success, ) = msg.sender.call{value: nativeBalance}("");
        require(success, "BridgeReceiverv1: send fee");
      }
    }
  }

  function redeemAndSwapFromLcBridge(address account, uint256 stableamount, uint256 fee, address unirouter, address[] memory path) public onlyManager {
    uint256 amount = ILiquidCryptoBridge_v2(bridge).redeem(stableamount, address(this), 0, true);

    if (fee > 0) {
      if (amount > fee) {
        IWETH(path[0]).withdraw(fee);
        (bool success, ) = msg.sender.call{value: fee}("");
        require(success, "BridgeReceiverv1: send fee");
        amount -= fee;
      }
      else {
        IWETH(path[0]).withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "BridgeReceiverv1: send fee");
        amount = 0;
      }
    }

    if (amount > 0) {
      _approveTokenIfNeeded(path[0], unirouter);
      uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
      _removeAllowances(path[0], unirouter);

      IERC20(path[path.length-1]).safeTransfer(account, amounts[amounts.length-1]);
    }
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }

  function _removeAllowances(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) > 0) {
      IERC20(token).approve(spender, 0);
    }
  }
}