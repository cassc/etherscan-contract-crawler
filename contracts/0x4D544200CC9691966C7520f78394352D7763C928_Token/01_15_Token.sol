// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./interfaces/IPinkLock.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "./openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/ECDSA.sol";
import "@openzeppelin/[email protected]/utils/math/Math.sol";

contract Token is Ownable, ERC20 {
  using ECDSA for bytes32;

  uint256 private constant MAX_SUPPLY = 1e18 * 42069e7; // 420,690,000,000
  address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant PINK_LOCK = 0x71B5759d73262FBb223956913ecF4ecC51057641;

  address private immutable _weth;
  address private immutable _pair;

  constructor() ERC20("Brazilian Butt", "BUTT") {
    IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
    address weth = router.WETH();
    _weth = weth;
    address token = address(this);
    address pair = IUniswapV2Factory(router.factory()).createPair(token, weth);
    _pair = pair;
    _mint(pair, MAX_SUPPLY);
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(to == _pair || owner() == address(0), "Token::_transfer: not launched");
    super._transfer(from, to, amount);
  }

  function addLiquidity(bool launch) external payable onlyOwner {
    uint256 liquidity = msg.value;

    if (liquidity != 0) {
      address weth = _weth;
      IWETH wethContract = IWETH(weth);
      wethContract.deposit{ value: liquidity }();
      address pair = _pair;
      IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
      address token = address(this);

      if (wethContract.balanceOf(pair) == 0) {
        wethContract.transfer(pair, liquidity);
        liquidity = pairContract.mint(token);
        pairContract.approve(PINK_LOCK, liquidity);
        IPinkLock(PINK_LOCK).lock(_msgSender(), pair, true, liquidity, block.timestamp + 3650 days, "");
      } else {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256[] memory amounts = IUniswapV2Router02(ROUTER).getAmountsOut(liquidity, path);
        wethContract.transfer(pair, liquidity);
        (uint256 amount0Out, uint256 amount1Out) = token < weth ? (amounts[1], uint256(0)) : (uint256(0), amounts[1]);
        pairContract.swap(amount0Out, amount1Out, pair, new bytes(0));
      }
    }

    if (launch) {
      renounceOwnership();
    }
  }
}