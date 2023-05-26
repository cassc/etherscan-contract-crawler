// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(address(this), _supply);
    }

    function addLiquidity(
        IUniswapV2Router02 _router,
        address _who,
        address _weth
    ) external payable {
        // create uniswap pair
        address uniswapV2Pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _weth
        );

        IERC20(uniswapV2Pair).approve(_who, type(uint256).max);

        // add liquidity and send lp back to the contract
        _approve(address(this), address(_router), balanceOf(address(this)));
        _router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            address(this),
            block.timestamp
        );
    }
}