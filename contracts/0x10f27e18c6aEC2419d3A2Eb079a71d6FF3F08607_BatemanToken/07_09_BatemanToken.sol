// SPDX-License-Identifier: MIT
// https://www.btmn.xyz/

pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IUniswapRouter02} from "./IUniswapRouter02.sol";

contract BatemanToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public taxPercentage = 5;
    address public pair;
    IUniswapRouter02 public uniswapRouter =
        IUniswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool public maxBuyEnabled;
    uint256 public maxBuyAmount;

    constructor() ERC20("Bateman Token", "BTMN") {
        maxBuyEnabled = true;
        maxBuyAmount = 420420420420 * 2 * 10 ** 16; // 2% of supply
        _mint(msg.sender, 420420420420 * 10 ** decimals()); // 90% of supply
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address from = _msgSender();
        _taxedTransfer(from, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _taxedTransfer(from, to, amount);

        return true;
    }

    function _taxedTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if ((from == pair) && msg.sender != owner()) {
            // is buy
            if (maxBuyEnabled) {
                require(
                    amount <= maxBuyAmount,
                    "You can't buy more than 2% of the supply at once"
                );
            }
            _transfer(from, to, amount);
        } else if ((to == pair) && msg.sender != owner()) {
            // is sell
            uint256 taxAmount = (amount * taxPercentage) / 100;
            _transfer(from, to, amount - taxAmount);
            _swapTokenForETH(taxAmount);
        } else _transfer(from, to, amount);

        return true;
    }

    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function toggleMaxBuy(bool enabled) public onlyOwner {
        maxBuyEnabled = enabled;
    }

    function setMaxBuyAmount(uint256 amount) public onlyOwner {
        maxBuyAmount = amount;
    }

    function withdrawTaxETH() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function rescueTokens(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setPairAddress(address _pair) external onlyOwner {
        pair = _pair;
    }

    receive() external payable {}

    fallback() external payable {}
}