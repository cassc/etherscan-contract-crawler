// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Token is Ownable, ERC20Burnable {
  address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  address public immutable router;
  address public immutable pair;

  constructor() ERC20("Bens Finale", "$FINALE") {
    router = ROUTER;
    IUniswapV2Router02 routerContract = IUniswapV2Router02(ROUTER);
    pair = IUniswapV2Factory(routerContract.factory()).createPair(address(this), routerContract.WETH());
    _mint(_sender, 1e9 * 10 ** decimals()); // 1B
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    require(to == _sender || to == pair || owner() == address(0), "Token::_beforeTokenTransfer: not launched");
    super._beforeTokenTransfer(from, to, amount);
  }
}