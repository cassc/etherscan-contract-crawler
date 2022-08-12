// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Utilities is Ownable {
    address internal uniswapRouter;
    mapping (uint256 => address) internal usdc;
    mapping (uint256 => address) internal usdt;

    constructor() {
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        usdc[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		    usdc[4] = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
    }

    function _getChainID() internal view returns (uint256) {
      uint256 id;
      assembly {
        id := chainid()
      }
      return id;
    }
}