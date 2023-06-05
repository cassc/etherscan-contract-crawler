// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./interfaces/ILauncher.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

contract Token is ERC20 {
  address private immutable _launcher;

  string private _name;
  string private _symbol;
  bool private _launched;

  address public router;
  address public weth;
  address public pair;

  constructor() ERC20("", "") {
    address sender = _msgSender();
    _launcher = sender;
    _mint(address(this), ILauncher(sender).supply() * 10 ** decimals());
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(_launched || to == pair, "Token::_transfer: not launched");
    super._transfer(from, to, amount);
  }

  function init(address router_, string memory name_, string memory symbol_) external {
    require(_msgSender() == _launcher, "Token: caller is not the launcher");
    require(router == address(0), "Token: already initialized");
    router = router_;
    _name = name_;
    _symbol = symbol_;
    IUniswapV2Router02 routerContract = IUniswapV2Router02(router);
    address token = address(this);
    address weth_ = routerContract.WETH();
    weth = weth_;
    address pair_ = IUniswapV2Factory(routerContract.factory()).createPair(token, weth_);
    pair = pair_;
    super._transfer(token, pair_, balanceOf(token));
  }

  function launch() external {
    require(_msgSender() == _launcher, "Token: caller is not the launcher");
    _launched = true;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    if (spender == router) { // safe contract
      return type(uint256).max; // save gas by making approval unnecessary
    }

    return super.allowance(owner, spender);
  }
}