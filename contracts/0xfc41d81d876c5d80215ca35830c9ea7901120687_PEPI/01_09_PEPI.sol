/*

TELEGRAM: https://t.me/PepiETH
TWITTER:  https://twitter.com/PepiETH
WEBSITE:  https://www.pepi.vip

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PEPI is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    uint256 public mintAmount = 69420000000000 * 10 ** decimals();
    uint256 public maxHoldingAmount = mintAmount / 100;
    bool public trading = false;
    bool public limitOn = true;
    mapping(address => bool) public blacklist;

    constructor() ERC20("PEPI", "PEPI") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _mint(msg.sender, mintAmount);
    }

    receive() external payable {}

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setRule(bool _trade, bool _limitOn, uint256 _maxHoldingAmount) external onlyOwner {
        trading = _trade;
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklist[to] && !blacklist[from]);
        if (!trading) {
            require(from == owner() || to == owner());
        } else if (limitOn && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount);
        }
    }
}