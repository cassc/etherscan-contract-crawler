// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HamsterCoin is ERC20, Ownable {
  address public taxWallet;
  address public uniswapV2Pair;
  uint256 public taxEndTime; // Initialised to 48 hours from when the uniswap V2 pair is set
  uint256 public constant BUY_TAX = 2; // 2% in the first 48 hours
  uint256 public constant SELL_TAX = 4; // 4% in the first 48 hours

  constructor(address taxWallet_) ERC20("Hamster Coin", "$HAMSTR") {
    _mint(msg.sender, 6_900_000_000_000_000 * 1e18);
    taxWallet = taxWallet_;
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override {
    if (uniswapV2Pair == address(0)) {
      require(from == owner() || to == owner(), "Trading not started");
      super._transfer(from, to, amount);
      return;
    }

    // buy/sell tax applies to DEX trading in the first 24 hours
    if (block.timestamp < taxEndTime) {
      uint256 tax;
      if (uniswapV2Pair == from) {
        // buying $HAM
        tax = (amount * BUY_TAX) / 100;
      } else if (uniswapV2Pair == to) {
        // sell $HAM
        tax = (amount * SELL_TAX) / 100;
      }

      if (tax > 0) {
        super._transfer(from, taxWallet, tax);
        amount -= tax;
      }
    }

    super._transfer(from, to, amount);
  }

  function startTrading(address uniswapV2PairAddress) external onlyOwner {
    require(uniswapV2Pair == address(0), "Trading already started");

    uniswapV2Pair = uniswapV2PairAddress;
    taxEndTime = block.timestamp + (48 * 60 * 60); //Apply tax for 48 hours
  }
}