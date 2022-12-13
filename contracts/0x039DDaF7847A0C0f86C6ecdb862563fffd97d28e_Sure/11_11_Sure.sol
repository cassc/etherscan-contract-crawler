// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Sure is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public tradingOpen;
    uint256 public launchTime;
    bool private _addingLP;

    address private _marketingWallet;

    uint256 public maxWalletSize;

    uint256 public taxAmount = 2;

    constructor() ERC20("Sure", "SURE") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uint256 _totalSupply = 1_000_000_000 * 10**decimals();
        maxWalletSize = _totalSupply / 100;

        _mint(msg.sender, _totalSupply);
    }

    function launch(address marketingWallet, address devWallet) external payable onlyOwner {
        require(launchTime == 0, "Token already launched");
        launchTime = block.timestamp;

        _addingLP = true;

        _marketingWallet = marketingWallet;

        uint256 _lpSupply = (totalSupply() * 94) / 100;
        uint256 _marketingSupply = (totalSupply() * 2) / 100;
        uint256 _devSupply = (totalSupply() * 4) / 100;
        require(_lpSupply + _marketingSupply + _devSupply == totalSupply(), "Invalid initial allocations");
        _transfer(owner(), marketingWallet, _marketingSupply);
        _transfer(owner(), devWallet, _devSupply);

        _transfer(owner(), address(this), _lpSupply);
        _addLiquidity(_lpSupply, msg.value);

        _addingLP = false;
    }

    receive() external payable {}

    function updateTradingOpen(bool _tradingOpen) external onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function updateMaxWalletSize(uint256 _maxWalletSize) external onlyOwner {
        require(
            _maxWalletSize >= (totalSupply() / 100),
            "Max Wallet Size cannot be less than 1% of total supply."
        );
        require(
            _maxWalletSize <= totalSupply(),
            "Max Wallet Size cannot exceed total supply."
        );
        maxWalletSize = _maxWalletSize;
    }


    function updateMarketingWallet(address marketingWallet) external onlyOwner {
        _marketingWallet = marketingWallet;
    }

    function updateTaxAmount(uint256 _taxAmount) external onlyOwner {
        require(_taxAmount <= 10, "Tax amount cannot exceed 10%");
        require(_taxAmount >= 0, "Tax amount must be at least 0%");
        taxAmount = _taxAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (_addingLP) {
            super._transfer(from, to, amount);
            return;
        }


        if (from != owner() && to != owner()) {
            require(tradingOpen, "Cannot transfer until trading is open");

            require(
                amount <= maxWalletSize,
                "Amount exceeds maximum wallet size"
            );

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(
                    balanceOf(to) + amount <= maxWalletSize,
                    "Balance will exceed max wallet size!"
                );
            }
            if (to == uniswapV2Pair) {
                require(
                    balanceOf(from) - amount >= 0,
                    "Balance will be less than 0!"
                );
            }
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= maxWalletSize,
                    "Balance will exceed max wallet size!"
                );
                require(
                    balanceOf(from) - amount >= 0,
                    "Balance will be less than 0!"
                );
            }

            uint256 tax = 0;
            if ((from == uniswapV2Pair && to != address(uniswapV2Router)) || to == uniswapV2Pair) {
                tax = (amount * taxAmount) / 100;
                if (tax > 0) {
                    super._transfer(from, _marketingWallet, tax);
                }
            }
            amount -= tax;
        }

        super._transfer(from, to, amount);
    }


    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

}