// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interface/ILiquidCryptoBridge_v1.sol";
import "./../interface/IUniswapRouterETH.sol";
import "./../interface/ILiquidCZapUniswapV2.sol";
import "./../interface/IWETH.sol";

contract Basket is Ownable {
  address public bridge;

  mapping (address => bool) public managers;
  // vault -> account -> amount
  mapping (address => mapping (address => uint256)) public xlpSupply;

  struct Swaper {
    address router;
    address[] path0;
    address[] path1;
  }

  constructor(address _bridge) {
    managers[msg.sender] = true;
    bridge = _bridge;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  receive() external payable {
  }

  function deposit(address account, address liquidCZap, address vault, address router, address[] calldata path) public payable {
    IWETH(path[0]).deposit{value: msg.value}();
    _deposit(account, liquidCZap, vault, router, path, msg.value);
  }

  function depositViaBridge(uint256 withdrawAmount, uint256 fee, address account, address liquidCZap, address vault, address router, address[] calldata path) public {
    ILiquidCryptoBridge_v1(bridge).withdrawForUser(address(this), true, withdrawAmount, fee);
    uint256 amount = IERC20(path[0]).balanceOf(address(this));
    _deposit(account, liquidCZap, vault, router, path, amount);
  }

  function _deposit(address account, address liquidCZap, address vault, address router, address[] calldata path, uint256 amount) private {
    _approveTokenIfNeeded(path[0], router);
    if (path.length > 1) {
      IUniswapRouterETH(router).swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }
    
    uint256 tokenbalance = IERC20(path[path.length-1]).balanceOf(address(this));
    _approveTokenIfNeeded(path[path.length-1], liquidCZap);

    uint256 oldxlpbalance = IERC20(vault).balanceOf(address(this));
    ILiquidCZapUniswapV2(liquidCZap).LiquidCIn(vault, 0, path[path.length-1], tokenbalance);
    uint256 xlpbalance = IERC20(vault).balanceOf(address(this));
    xlpSupply[vault][account] = xlpSupply[vault][account] + xlpbalance - oldxlpbalance;
    // IERC20(vault).transfer(account, xlpbalance);
  }

  function moveBasket2Pool(address vault, uint256 amount) public {
    require(amount <= xlpSupply[vault][msg.sender], "Your balance is not enough");
    xlpSupply[vault][msg.sender] = xlpSupply[vault][msg.sender] - amount;
    IERC20(vault).transfer(msg.sender, amount);
  }

  function withdraw(address account, address liquidCZap, address vault, Swaper memory swper, uint256 amount, uint256 fee) public onlyManager {
    _withdraw(liquidCZap, vault, swper, amount);
    uint256 outAmount = address(this).balance;
    outAmount = outAmount - fee;

    (bool success1, ) = account.call{value: outAmount}("");
    require(success1, "Failed to withdraw");

    if (fee > 0) {
      (bool success2, ) = msg.sender.call{value: outAmount}("");
      require(success2, "Failed to refund fee");
    }

    xlpSupply[vault][account] = xlpSupply[vault][account] - amount;
  }

  function withdrawToBridge(address account, address liquidCZap, address vault, Swaper memory swper, uint256 amount, uint256 fee) public onlyManager {
    _withdraw(liquidCZap, vault, swper, amount);
    uint256 inAmount = address(this).balance;
    
    ILiquidCryptoBridge_v1(bridge).depositForUser{value: inAmount}(fee);

    xlpSupply[vault][account] = xlpSupply[vault][account] - amount;
  }

  function _withdraw(address liquidCZap, address vault, Swaper memory swper, uint256 amount) private {
    _approveTokenIfNeeded(vault, liquidCZap);
    ILiquidCZapUniswapV2(liquidCZap).LiquidCOut(vault, amount);

    if (swper.path0.length > 1) {
      _approveTokenIfNeeded(swper.path0[0], swper.router);
      uint256 t0amount = IERC20(swper.path0[0]).balanceOf(address(this));
      IUniswapRouterETH(swper.router).swapExactTokensForTokens(t0amount, 0, swper.path0, address(this), block.timestamp);
    }
    if (swper.path1.length > 1) {
      _approveTokenIfNeeded(swper.path1[0], swper.router);
      uint256 t1amount = IERC20(swper.path1[0]).balanceOf(address(this));
      IUniswapRouterETH(swper.router).swapExactTokensForTokens(t1amount, 0, swper.path1, address(this), block.timestamp);
    }

    address weth = swper.path0[swper.path0.length-1];
    uint256 wethBalance = IERC20(weth).balanceOf(address(this));
    IWETH(weth).withdraw(wethBalance);
  }

  function setBridge(address addr) public onlyOwner {
    bridge = addr;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }
}