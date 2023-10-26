// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Jok is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromFees;

    uint256 public liquidityFeeOnBuy;
    uint256 public liquidityFeeOnSell;

    uint256 public companyFeeOnBuy;
    uint256 public companyFeeOnSell;

    uint256 private _totalFeesOnBuy;
    uint256 private _totalFeesOnSell;

    address public companyWallet;
    address public liquidityWallet;

    uint256 public swapTokensAtAmount;
    bool private swapping;

    bool public swapEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(
        address[] indexed accounts,
        bool isExcluded
    );

    event companyWalletChanged(address companyWallet);
    event LiquidityWalletChanged(address liquidityWallet);
    event UpdateBuyFees(uint256 liquidityFeeOnBuy, uint256 companyFeeOnBuy);
    event UpdateSellFees(uint256 liquidityFeeOnSell, uint256 companyFeeOnSell);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndSendcompany(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    constructor() ERC20("Jok", "JOK") {
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        liquidityFeeOnBuy = 1;
        liquidityFeeOnSell = 1;

        companyFeeOnBuy = 1;
        companyFeeOnSell = 1;

        _totalFeesOnBuy = liquidityFeeOnBuy + companyFeeOnBuy;
        _totalFeesOnSell = liquidityFeeOnSell + companyFeeOnSell;

        companyWallet = 0x9d438A53b2e4E9d453331Da806EC4aE31eba1A0A;
        liquidityWallet = 0x9d438A53b2e4E9d453331Da806EC4aE31eba1A0A;

        _isExcludedFromFees[0x9d438A53b2e4E9d453331Da806EC4aE31eba1A0A] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;

        _mint(
            0x9d438A53b2e4E9d453331Da806EC4aE31eba1A0A,
            777 * 1e9 * (10 ** decimals())
        );
        swapTokensAtAmount = totalSupply() / 5_000;

        tradingEnabled = false;
        swapEnabled = false;
    }

    receive() external payable {}

    function claimStuckTokens(address token) external onlyOwner {
        require(
            token != address(this),
            "Owner cannot claim contract's balance of its own tokens"
        );
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateUniSwapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function updateBuyFees(
        uint256 _liquidityFeeOnBuy,
        uint256 _companyFeeOnBuy
    ) external onlyOwner {
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        companyFeeOnBuy = _companyFeeOnBuy;

        _totalFeesOnBuy = liquidityFeeOnBuy + companyFeeOnBuy;

        require(
            _totalFeesOnBuy + _totalFeesOnSell <= 10,
            "Total Fees cannot exceed the maximum"
        );

        emit UpdateBuyFees(liquidityFeeOnBuy, companyFeeOnBuy);
    }

    function updateSellFees(
        uint256 _liquidityFeeOnSell,
        uint256 _companyFeeOnSell
    ) external onlyOwner {
        liquidityFeeOnSell = _liquidityFeeOnSell;
        companyFeeOnSell = _companyFeeOnSell;

        _totalFeesOnSell = liquidityFeeOnSell + companyFeeOnSell;

        require(
            _totalFeesOnBuy + _totalFeesOnSell <= 10,
            "Total Fees cannot exceed the maximum"
        );

        emit UpdateSellFees(liquidityFeeOnSell, companyFeeOnSell);
    }

    function changecompanyWallet(address _companyWallet) external onlyOwner {
        require(
            _companyWallet != companyWallet,
            "company wallet is already that address"
        );
        require(
            _companyWallet != address(0),
            "company wallet cannot be the zero address"
        );
        companyWallet = _companyWallet;

        emit companyWalletChanged(companyWallet);
    }

    function changeLiquidityWallet(
        address _liquidityWallet
    ) external onlyOwner {
        require(
            _liquidityWallet != liquidityWallet,
            "company wallet is already that address"
        );
        require(
            _liquidityWallet != address(0),
            "company wallet cannot be the zero address"
        );
        liquidityWallet = _liquidityWallet;

        emit LiquidityWalletChanged(liquidityWallet);
    }

    bool public tradingEnabled;

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        swapEnabled = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            tradingEnabled ||
                _isExcludedFromFees[from] ||
                _isExcludedFromFees[to],
            "Trading not yet enabled!"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            to == uniswapV2Pair &&
            _totalFeesOnBuy + _totalFeesOnSell > 0 &&
            swapEnabled
        ) {
            swapping = true;

            uint256 totalFee = _totalFeesOnBuy + _totalFeesOnSell;
            uint256 liquidityShare = liquidityFeeOnBuy + liquidityFeeOnSell;
            uint256 companyShare = companyFeeOnBuy + companyFeeOnSell;

            if (liquidityShare > 0) {
                uint256 liquidityTokens = (contractTokenBalance *
                    liquidityShare) / totalFee;
                swapAndLiquify(liquidityTokens);
            }

            if (companyShare > 0) {
                uint256 companyTokens = (contractTokenBalance * companyShare) /
                    totalFee;
                swapAndSendcompany(companyTokens);
            }

            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
        } else if (from == uniswapV2Pair) {
            _totalFees = _totalFeesOnBuy;
        } else if (to == uniswapV2Pair) {
            _totalFees = _totalFeesOnSell;
        } else {
            _totalFees = 0;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount > totalSupply() / 1_000_000,
            "SwapTokensAtAmount must be greater than 0.0001% of total supply"
        );
        swapTokensAtAmount = newAmount;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendcompany(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        payable(companyWallet).sendValue(newBalance);

        emit SwapAndSendcompany(tokenAmount, newBalance);
    }
}