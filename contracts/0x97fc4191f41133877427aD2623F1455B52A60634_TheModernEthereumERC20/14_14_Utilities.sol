// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Utilities is Ownable {
    address internal uniswapRouter;
    mapping (uint256 => address) internal usdc;
    mapping (uint256 => address) internal usdt;

    struct Taxes {
      uint256 marketingFee;
      uint256 treasuryFee;
      uint256 devFee;
    }

    constructor() {
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        usdc[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		    usdc[5] = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        usdt[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
		    usdt[5] = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9;
    }

    function _getChainID() internal view returns (uint256) {
      uint256 id;
      assembly {
        id := chainid()
      }
      return id;
    }

    function updateUSDC(uint256 _chainId, address _usdc) external onlyOwner {
      usdc[_chainId] = _usdc;
    }
}