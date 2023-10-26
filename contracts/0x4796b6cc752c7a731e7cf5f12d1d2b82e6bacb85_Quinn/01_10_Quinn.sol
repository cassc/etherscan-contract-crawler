// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Quinn is ERC20, Ownable {
    event SwapBackSuccess(
        uint256 tokenAmount,
        uint256 ethAmountReceived,
        bool success
    );
    bool private swapping;
    address public feeWallet =
        address(0x85A45AC4Fc93749d3d268a250Ffa7F18134d3131); //marketing wallet

    uint256 _totalSupply = 10_000_000 * 1e18;
    uint256 public maxTransactionAmount = (_totalSupply * 10) / 1000; // 1% from total supply maxTransactionAmountTxn, 100,000 tokens
    uint256 public swapTokensAtAmount = (_totalSupply * 10) / 10000; // 0.1% swap tokens at this amount. (10_000_000 * 10) / 10000 = 0.1%(10000 tokens) of the total supply
    uint256 public maxWallet = (_totalSupply * 10) / 1000; // 1% from total supply maxWallet

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false; //cannot be disabled once trading is enabled

    uint256 public buyFees = 30;
    uint256 public sellFees = 30;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor() ERC20("Quinn", "QUINN") {
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(feeWallet, true);

        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(feeWallet, true);

        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable (sets sell fees to 1%)
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        sellFees = 1;
        buyFees = 1;
        return true;
    }

    function excludeFromMaxTransaction(
        address addressToExclude,
        bool isExcluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[addressToExclude] = isExcluded;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
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
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //uni router
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), totalSupply());
    }

    function addLiquidity() external payable onlyOwner {
        // approve token transfer to cover all possible scenarios
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //uni router
        );

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), totalSupply());
        // add the liquidity
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this), //token address
            totalSupply(), // liquidity amount
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), // LP tokens are sent to the owner
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function updateFeeWallet(address feeWallet_) public onlyOwner {
        feeWallet = feeWallet_;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (limitsInEffect) {
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
                        "Trading is not enabled yet."
                    );
                }

                //when buy
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
                //when sell
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
        }

        if (
            swapEnabled && //if this is true
            !swapping && //if this is false
            !automatedMarketMakerPairs[from] && //if this is false
            !_isExcludedFromFees[from] && //if this is false
            !_isExcludedFromFees[to] //if this is false
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellFees > 0) {
                fees = (amount * sellFees) / 100;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                fees = (amount * buyFees) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance >= swapTokensAtAmount) {
            uint256 amountToSwapForETH = swapTokensAtAmount;
            swapTokensForEth(amountToSwapForETH);
            uint256 amountEthToSend = address(this).balance;
            (success, ) = address(feeWallet).call{value: amountEthToSend}("");
            emit SwapBackSuccess(amountToSwapForETH, amountEthToSend, success);
        }
    }
}