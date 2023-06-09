// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/*


.------..------..------..------..------..------..------..------..------..------..------..------..------..------.
|F.--. ||U.--. ||U.--. ||U.--. ||U.--. ||U.--. ||L.--. ||L.--. ||L.--. ||L.--. ||L.--. ||L.--. ||S.--. ||S.--. |
| :(): || (\/) || (\/) || (\/) || (\/) || (\/) || :/\: || :/\: || :/\: || :/\: || :/\: || :/\: || :/\: || :/\: |
| ()() || :\/: || :\/: || :\/: || :\/: || :\/: || (__) || (__) || (__) || (__) || (__) || (__) || :\/: || :\/: |
| '--'F|| '--'U|| '--'U|| '--'U|| '--'U|| '--'U|| '--'L|| '--'L|| '--'L|| '--'L|| '--'L|| '--'L|| '--'S|| '--'S|
`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'


*/

/// @title FUUL Token
/// Telegram: https://t.me/fuultoken
/// Twitter: https://twitter.com/FUULTOKEN

contract FUUL is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1000000000000 * 10 ** 18;
    uint256 private _tax = 200; // 2% tax
    uint256 private _devTax = 100; // 1% from tax to pool
    uint256 private constant MAX_TAX = 10000;
    uint256 private lastSwapped;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public devVault;

    bool private taxExemption = true;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    receive() external payable {}

    constructor() ERC20("FUUL Token V2", "FUULv2") {
        _mint(msg.sender, MAX_SUPPLY);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        lastSwapped = block.timestamp;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 transferAmount = amount;
        if (
            !taxExemption &&
            (msg.sender == uniswapV2Pair || recipient == uniswapV2Pair) &&
            msg.sender != address(this) &&
            recipient != address(this)
        ) {
            uint256 taxAmount = calculateTax(amount);
            uint256 liquidityAmount = calculateLiquidityTax(amount);
            transferAmount = amount - taxAmount;
            super.transfer(address(this), liquidityAmount);
            super.transfer(devVault, taxAmount - liquidityAmount);
        }

        super.transfer(recipient, transferAmount);

        if (
            lastSwapped + 1 hours < block.timestamp &&
            balanceOf(address(this)) > 0
        ) swapAndLiquify();

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 transferAmount = amount;
        if (
            !taxExemption &&
            (msg.sender == uniswapV2Pair || recipient == uniswapV2Pair) &&
            sender != address(this) &&
            recipient != address(this)
        ) {
            uint256 taxAmount = calculateTax(amount);
            uint256 liquidityAmount = calculateLiquidityTax(amount);
            transferAmount = amount - taxAmount;
            super.transferFrom(sender, address(this), liquidityAmount);
            super.transferFrom(sender, devVault, taxAmount - liquidityAmount);
        }

        super.transferFrom(sender, recipient, transferAmount);

        if (
            lastSwapped + 1 hours < block.timestamp &&
            balanceOf(address(this)) > 0
        ) swapAndLiquify();

        return true;
    }

    function setDevVault(address devVault_) external onlyOwner {
        devVault = devVault_;
    }

    function toggleTax() external onlyOwner {
        taxExemption = !taxExemption;
    }

    function calculateTax(uint256 amount) public view returns (uint256) {
        return (amount * _tax) / MAX_TAX;
    }

    function calculateLiquidityTax(
        uint256 amount
    ) public view returns (uint256) {
        return (amount * _devTax) / MAX_TAX;
    }

    function swapAndLiquify() public {
        uint256 contractTokenBalance = balanceOf(address(this));

        // Swap half of the tokens to ETH
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        // Swap tokens for ETH
        swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        // Add liquidity to Uniswap
        addLiquidity(otherHalf, newBalance);

        lastSwapped = block.timestamp;

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        require(
            tokenAmount > 0,
            "Swap tokens for ETH: tokenAmount should be greater than 0"
        );
        // Generate the Uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Approve the router to spend tokens
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        require(
            tokenAmount > 0,
            "Add liquidity: tokenAmount should be greater than 0"
        );
        require(
            ethAmount > 0,
            "Add liquidity: ethAmount should be greater than 0"
        );

        // Approve the router to spend tokens
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}