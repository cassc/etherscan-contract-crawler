// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract TGCToken is ERC20, ERC20Burnable, Ownable {
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    IUniswapV2Pair public pair;

    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 18;
    uint256 constant LP_BPS = 2000;

    bool public isTradingEnabled;
    bool public isLaunched;

    event TokenLaunched();

    constructor() ERC20("TG.Casino", "TGC") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        factory = IUniswapV2Factory(router.factory());
        _approve(address(this), address(router), type(uint256).max);
        _mint(_msgSender(), (MAX_SUPPLY * (10_000 - LP_BPS)) / 10_000);
    }

    function launch() external payable onlyOwner {
        require(!isLaunched, "already launched");
        _mint(address(this), (MAX_SUPPLY * LP_BPS) / 10_000);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        pair = IUniswapV2Pair(factory.getPair(address(this), router.WETH()));
        require(totalSupply() == MAX_SUPPLY, "numbers dont add up");
        isLaunched = true;
        emit TokenLaunched();
    }

    function enableTrading() external onlyOwner {
        require(isLaunched, "not yet launched");
        require(!isTradingEnabled, "trading already enabled");
        isTradingEnabled = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isLaunched && !isTradingEnabled) {
            require(
                from != address(pair) && to != address(pair),
                "trading disabled"
            );
        }

        super._transfer(from, to, amount);
    }
}