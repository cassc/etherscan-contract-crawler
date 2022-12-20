// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interface/IUniswapRouterETH.sol";
import "./../interface/IWETH.sol";

contract Basketv2wirhdrawer is Ownable {
  mapping (address => bool) public managers;

  address public unirouter;
  address[] public stargateInputToNative;
  address public native;
  address public stargateInput;

  constructor(
    address _unirouter,
    address[] memory _stargateInputToNative
  ) {
    managers[msg.sender] = true;
    unirouter = _unirouter;
    stargateInputToNative = _stargateInputToNative;
    stargateInput = _stargateInputToNative[0];
    native = _stargateInputToNative[_stargateInputToNative.length - 1];
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  receive() external payable {
  }

  function withdrawWithStargate(address account, uint256 amount, uint256 fee) public onlyManager {
    _approveTokenIfNeeded(stargateInput, unirouter);
    IUniswapRouterETH(unirouter).swapExactTokensForTokens(amount, 0, stargateInputToNative, address(this), block.timestamp);
    _removeAllowances(stargateInput, unirouter);
    uint256 nativeBalance = IERC20(native).balanceOf(address(this));
    IWETH(native).withdraw(nativeBalance);

    if (nativeBalance >= fee) {
      (bool success2, ) = payable(account).call{value: nativeBalance - fee}("");
      require(success2, "Failed to refund fee");
    }

    if (fee > 0) {
      (bool success2, ) = msg.sender.call{value: fee}("");
      require(success2, "Failed to refund fee");
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