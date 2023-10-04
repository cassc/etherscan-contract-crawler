// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "./oz/token/ERC20/IERC20.sol";
import {IERC165} from "./oz/utils/introspection/IERC165.sol";
import {Ownable} from "./oz/access/Ownable.sol";
import {SafeERC20} from "./oz/token/ERC20/utils/SafeERC20.sol";

import {IBuyTaxReceiver} from "./interfaces/IBuyTaxReceiver.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

contract BenBuyTaxReceiver is Ownable, IBuyTaxReceiver, IERC165 {
  using SafeERC20 for IERC20;

  IUniswapV2Router02 public immutable router;
  address public immutable wNative;

  address public benV2;

  error OnlyBen();

  modifier onlyBen() {
    if (msg.sender != benV2) {
      revert OnlyBen();
    }
    _;
  }

  constructor(IUniswapV2Router02 _router, address _wNative) {
    router = _router;
    wNative = _wNative;
  }

  function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
    return _interfaceId == type(IBuyTaxReceiver).interfaceId;
  }

  function _swap() private {
    uint256 balance = IERC20(benV2).balanceOf(address(this));
    if (balance > 0) {
      address[] memory path = new address[](2);
      path[0] = benV2;
      path[1] = wNative;

      router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        balance,
        0, // accept any amount of ETH
        path,
        owner(),
        block.timestamp
      );
    }
  }

  function swapCallback() external override onlyBen {
    _swap();
  }

  function forceSwap() external onlyOwner {
    _swap();
  }

  function setBen(address _benV2) external onlyOwner {
    benV2 = _benV2;
    if (address(router) != address(0)) {
      IERC20(_benV2).approve(address(router), type(uint256).max);
    }
  }

  function recoverTokens(address _token) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }
}