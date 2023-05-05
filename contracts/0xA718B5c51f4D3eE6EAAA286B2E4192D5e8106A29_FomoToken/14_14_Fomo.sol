// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FomoToken is Ownable, ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 immutable router;
    uint256 immutable maxHoldingAmount;
    address immutable uniswapV2Pair;

    bool public limited = true;
    bool public tradingEnabled = false;

    constructor(IUniswapV2Router02 _router) ERC20("UpOnly", "UPONLY") {
        router = _router;

        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        uniswapV2Pair = factory.createPair(_router.WETH(), address(this));

        uint256 totalSupply = 69_420_420_420_420 * 1e18;
        maxHoldingAmount = totalSupply.div(100);
        _mint(msg.sender, totalSupply);
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function removeLimits() external onlyOwner {
        limited = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            owner() == from || owner() == to || tradingEnabled,
            "!tradingEnabled"
        );
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}