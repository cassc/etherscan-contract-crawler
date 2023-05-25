// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Matrix is ERC20, Ownable {
    uint256 private constant _initialSupply = 100_000_101_010_100 * 10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor() ERC20("Matrix", "MATRIX") {
        _mint(msg.sender, _initialSupply);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function burn(address tokenOwner, uint amount) external {
        require(msg.sender == tokenOwner || allowance(tokenOwner, msg.sender) >= amount, "Not enough allowances");
        if (msg.sender != tokenOwner) {
            _approve(tokenOwner, msg.sender, _allowances[tokenOwner][msg.sender] - amount);
        }
        _burn(tokenOwner, amount);
    }
}