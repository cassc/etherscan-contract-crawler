// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./interfaces/ILauncher.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Token is Ownable, ERC20Burnable {
  address private immutable _launcher;

  string private _name;
  string private _symbol;

  address public weth;
  address public pair;

  constructor() ERC20("", "") {
    address sender = _msgSender();
    _launcher = sender;
    _mint(sender, ILauncher(sender).supply() * 10 ** decimals());
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
    require(to == _launcher || to == pair || owner() == address(0), "Token::_beforeTokenTransfer: not launched");
    from;
    amount;
  }

  function initialize(string memory name_, string memory symbol_, address router) external onlyOwner {
    require(pair == address(0), "Token::initialize: already initialized");
    _name = name_;
    _symbol = symbol_;
    IUniswapV2Router02 routerContract = IUniswapV2Router02(router);
    address weth_ = routerContract.WETH();
    weth = weth_;
    address pair_ = IUniswapV2Factory(routerContract.factory()).createPair(address(this), weth_);
    pair = pair_;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }
}