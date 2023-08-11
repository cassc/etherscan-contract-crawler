// SPDX-License-Identifier: MIT

/*

https://t.me/RouletteBotERC20

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Roulette is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private _excludedFromTaxes;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // taxes
    uint256 public buyTax = 5;
    uint256 public sellTax = 5;

    uint256 public blockOffset = 5;

    // max per wallet (% of the currentSupply)
    uint256 public maxAmountPerWalletSupplyPercent = 2;
    uint256 public maxTxPerWalletSupplyPercent = 2;

    uint256 public maxAmountPerWallet;
    uint256 public maxTxPerWallet;

    // uniswap
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniPair;
    mapping(address => bool) public LPs;

    bool public tradingOpen = false;
    mapping(address => uint256) private _accountTransferTimestamp;
    bool private swapping;

    uint256 public currentSupply;
    uint256 public canSwapTokens;

    address public marketingWallet;

    constructor(address _uniswapV2RouterAddress) ERC20("RouletteBot", "ROUL") {
        uint256 tokenInitialSupply = 100_000_000 * 1e18;
        currentSupply = tokenInitialSupply;

        maxTxPerWallet = (currentSupply * maxTxPerWalletSupplyPercent) / 100;
        canSwapTokens = (currentSupply * 5) / 10000;
        maxAmountPerWallet =
            (currentSupply * maxAmountPerWalletSupplyPercent) /
            100;

        // UniV2 Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _uniswapV2RouterAddress
        );
        excludeFromMaxTx(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        // UniV2 LP
        uniPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        excludeFromMaxTx(address(uniPair), true);
        LPs[address(uniPair)] = true;

        excludeFromTaxes(owner(), true);
        excludeFromTaxes(address(this), true);
        excludeFromTaxes(address(0xdead), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(0xdead), true);

        marketingWallet = owner();
        _approve(owner(), address(uniswapV2Router), tokenInitialSupply);
        _mint(msg.sender, tokenInitialSupply);
    }

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function setMarketingWallet(address _new) external onlyOwner {
        marketingWallet = _new;
    }

    function excludeFromMaxTx(address _account, bool _status) public onlyOwner {
        _isExcludedMaxTransactionAmount[_account] = _status;
    }

    function excludeFromTaxes(address _account, bool _status) public onlyOwner {
        _excludedFromTaxes[_account] = _status;
    }

    function updateLimitsPercent(
        uint256 _maxTxPerWallet,
        uint256 _maxAmountPerWallet
    ) external onlyOwner {
        maxTxPerWalletSupplyPercent = _maxTxPerWallet;
        maxAmountPerWalletSupplyPercent = _maxAmountPerWallet;
        updateLimits();
    }

    function updateLimits() private {
        maxTxPerWallet = (currentSupply * maxTxPerWalletSupplyPercent) / 100;
        canSwapTokens = (currentSupply * 5) / 10000;
        maxAmountPerWallet =
            (currentSupply * maxAmountPerWalletSupplyPercent) /
            100;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            tradingOpen || _excludedFromTaxes[from] || _excludedFromTaxes[to],
            "Trading not open"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool buy = LPs[from];
        bool sell = LPs[to];

        if (
            from != owner() &&
            to != owner() &&
            to != address(0xdead) &&
            !swapping
        ) {
            // massive buy protection
            if (
                to != owner() &&
                to != address(uniswapV2Router) &&
                to != address(uniPair)
            ) {
                require(
                    _accountTransferTimestamp[tx.origin] < block.number,
                    "One dex tx per block"
                );
                _accountTransferTimestamp[tx.origin] =
                    block.number +
                    blockOffset;
            }
            // max amount per tx
            if ((sell || buy) && !_isExcludedMaxTransactionAmount[from]) {
                require(
                    amount <= maxTxPerWallet,
                    "Amount exceeds the maxTxPerWallet"
                );
            }

            // max amount per wallet
            if (!sell && !_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxAmountPerWallet,
                    "Max wallet exceeded"
                );
            }
        }

        bool canSwap = balanceOf(address(this)) >= canSwapTokens;
        if (
            canSwap &&
            !swapping &&
            !buy &&
            !_excludedFromTaxes[from] &&
            !_excludedFromTaxes[to]
        ) {
            swapping = true;
            retrieveSwap();
            swapping = false;
        }

        // taxes
        if (!swapping && !_excludedFromTaxes[from] && !_excludedFromTaxes[to]) {
            uint256 taxes = 0;
            if (sell && sellTax > 0) {
                taxes = amount.mul(sellTax).div(100);
            } else if (buy && buyTax > 0) {
                taxes = amount.mul(buyTax).div(100);
            }
            if (taxes > 0) {
                super._transfer(from, address(this), taxes);
                amount -= taxes;
            }
        }

        // transfer
        super._transfer(from, to, amount);
    }

    function isExcludedFromTaxes(address account) public view returns (bool) {
        return _excludedFromTaxes[account];
    }

    function swapTokensToWETH(uint256 tokenAmount) private {
        // path : token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function retrieveSwap() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance > canSwapTokens * 20) {
            contractBalance = canSwapTokens * 20;
        }
        swapTokensToWETH(contractBalance);

        bool success;
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }(""); // marketing taxes
    }

    receive() external payable {}
}