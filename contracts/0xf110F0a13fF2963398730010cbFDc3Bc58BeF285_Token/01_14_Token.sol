// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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

  address private immutable _weth;
  address private immutable _pair;

  constructor() ERC20("RonDeSantis", "RDS") {
    IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
    address weth = router.WETH();
    _weth = weth;
    address token = address(this);
    address pair = IUniswapV2Factory(router.factory()).createPair(token, weth);
    _pair = pair;
    _mint(token, MAX_SUPPLY);
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
      wethContract.deposit{ value: msg.value }();
      address pair = _pair;
      wethContract.transfer(pair, msg.value);

      if (balanceOf(pair) == 0) {
        _transfer(address(this), pair, MAX_SUPPLY);
        IUniswapV2Pair(pair).mint(address(0)); // burn LP
      } else {
        (uint256 amount0Out, uint256 amount1Out) = address(this) < weth ? (1, 0) : (0, 1);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, pair, new bytes(0));
      }
    }

    if (launch) {
      renounceOwnership();
    }
  }
}