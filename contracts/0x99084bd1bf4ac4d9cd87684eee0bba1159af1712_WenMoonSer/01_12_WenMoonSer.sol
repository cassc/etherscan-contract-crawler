// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract WenMoonSer is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    constructor() ERC20("Wen Moon Ser", "Pamp Pls") {
        uint256 totalSupply = 6_666_666_666 * 1e18;
        _mint(msg.sender, totalSupply);
    }
}