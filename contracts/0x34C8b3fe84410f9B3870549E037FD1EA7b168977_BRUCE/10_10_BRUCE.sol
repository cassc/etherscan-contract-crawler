// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BRUCE is ERC20, ERC20Burnable, Ownable {
  IUniswapV2Router02 private immutable uniswapRouter;

  address public immutable uniswapPair;
  
  mapping(address => bool) public blacklists;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _totalSupply,
    address _uniswapRouter
  ) ERC20(_name, _symbol) {
    _mint(msg.sender, _totalSupply * 10 ** decimals());

    uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
      address(this),
      uniswapRouter.WETH()
    );
  }

  function blacklist(address[] calldata _addresses, bool _isBlacklisting) external onlyOwner {
    for (uint i; i < _addresses.length; i++) {
      // if (address(uniswapRouter) == _addresses[i]) continue;
      blacklists[_addresses[i]] = _isBlacklisting;
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    require(!blacklists[to] && !blacklists[from], "Blacklisted");
    super._beforeTokenTransfer(from, to, amount);
  }
}