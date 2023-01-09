// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import "./../interface/bridge/ILiquidCryptoBridge_v2.sol";
import "./../interface/IUniswapRouterETH.sol";
import "./../interface/IWETH.sol";

contract LcBridgeZapv1 is Ownable {
  using SafeERC20 for IERC20;

  address public bridge;

  mapping (address => bool) public managers;

  constructor(address _bridge) {
    managers[msg.sender] = true;
    bridge = _bridge;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LiquidC Basket v3: !manager");
    _;
  }

  receive() external payable {
  }

  function swap(address _account, uint256 _outChainID, address _unirouter, address[] memory _path, uint256 _amount) public {
    IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), _amount);
    _approveTokenIfNeeded(_path[0], _unirouter);
    uint256[] memory amounts = IUniswapRouterETH(_unirouter).swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
    _removeAllowances(_path[0], _unirouter);

    IWETH(_path[_path.length-1]).withdraw(amounts[amounts.length-1]);
    
    uint256 nativeBalance = amounts[amounts.length - 1];
    ILiquidCryptoBridge_v2(bridge).swap{value: nativeBalance}(_account, _account, _outChainID);
  }

  function setBridge(address _bridge) public onlyManager {
    bridge = _bridge;
  }
  
  function setManager(address _account, bool _access) public onlyOwner {
    managers[_account] = _access;
  }

  function withdrawBridgeRefundFee(uint256 _fee) public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: _fee}("");
    require(success, "Failed to withdraw");
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