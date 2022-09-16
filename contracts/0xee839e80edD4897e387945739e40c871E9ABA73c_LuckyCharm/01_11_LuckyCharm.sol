// SPDX-License-Identifier: MIT

pragma solidity >=0.8.8;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LuckyCharm is ERC20, Ownable {
    using SafeMath for uint256;

    //Contract functional variables
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public _maxTransactionAmount;
    mapping(address => bool) public _isExcludedFromLimit;
    uint256 public _swapTokensAtAmount;
    uint256 public _maxWallet;
    bool public _limitsInEffect = true;
    bool public _tradingActive = false;
    bool private _swapping;

    // Anti-bot
    mapping(address => uint256) private _lastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public _isTransferDelay = true;

    //Fees
    address public marketingWallet;
    address public devWallet;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    mapping(address => bool) private _isExcludedFromFees;

    //Uniswap
    IUniswapV2Router02 public router;
    address public pair;
    address public constant deadAddress = address(0xdead);

    constructor() ERC20("LuckyCharm", "LKCH") {
        setupSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uint256 _buyMarketingFee = 3;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 3;
        uint256 _sellMarketingFee = 3;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 3;

        _maxTransactionAmount = (TOTAL_SUPPLY / 100) * 10 + 1;
        _maxWallet = _maxTransactionAmount * 5;
        _swapTokensAtAmount = (TOTAL_SUPPLY / 100) * 5 + 1;

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee;

        marketingWallet = address(0xc7076087E90214FB7Cc970e79db01a857FB8abF7);
        // set as marketing wallet
        devWallet = owner();
        // set as dev wallet

        // exclude from paying fees or having max transaction amount
        setIsExcludeFromFees(owner(), true);
        setIsExcludeFromFees(address(this), true);
        setIsExcludeFromFees(address(0xdead), true);
        setIsExcludeFromFees(address(marketingWallet), true);

        setIsExcludeFromLimit(owner(), true);
        setIsExcludeFromLimit(address(this), true);
        setIsExcludeFromLimit(address(0xdead), true);
        setIsExcludeFromLimit(address(marketingWallet), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setupSwapRouter(address routerAddress) private {
        require(routerAddress != address(0), "Invalid router address");
        router = IUniswapV2Router02(routerAddress);
        pair = IUniswapV2Factory(router.factory()).getPair(
            address(this),
            router.WETH()
        );
        if (pair == address(0)) {
            pair = IUniswapV2Factory(router.factory()).createPair(
                address(this),
                router.WETH()
            );
        }
        setIsExcludeFromLimit(routerAddress, true);
        setIsExcludeFromLimit(address(pair), true);
    }

    receive() external payable {}

    function activeTrading() external onlyOwner {
        _tradingActive = true;
    }

    function removeLimits() external onlyOwner {
        _limitsInEffect = false;
    }

    function disableTransferDelay() external onlyOwner {
        _isTransferDelay = false;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= ((totalSupply() * 1) / 10000) / 1e18,
            "Swap amount cannot be lower than 0.01% total supply."
        );
        require(
            newAmount <= ((totalSupply() * 5) / 1000) / 1e18,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        _swapTokensAtAmount = newAmount * 1e18;
        return true;
    }

    function updateMaxTxnAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        _maxTransactionAmount = newAmount * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        _maxWallet = newNum * 1e18;
    }

    function setIsExcludeFromLimit(address updAds, bool isEx) public onlyOwner {
        _isExcludedFromLimit[updAds] = isEx;
    }

    function setIsExcludeFromFees(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromFees[account] = excluded;
    }

    function setIsExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!_tradingActive) {
            require(from == owner() || to == owner(), "Trading is not active.");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (_swapping) {
            super._transfer(from, to, amount);
            return;
        }

        if (_limitsInEffect) {
            if (
                //when buy
                from == pair && !_isExcludedFromLimit[to]
            ) {
                require(
                    amount <= _maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= _maxWallet,
                    "Max wallet exceeded"
                );
                // Delay on buy only
                if (_isTransferDelay) {
                    require(
                        _lastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _lastTransferTimestamp[tx.origin] = block.number;
                }
            } else if (
                //when sell
                to == pair && !_isExcludedFromLimit[from]
            ) {
                require(
                    amount <= _maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedFromLimit[to]) {
                // transfer
                require(
                    amount + balanceOf(to) <= _maxWallet,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        if (
            canSwap &&
            _tradingActive &&
            to == pair && //on sell
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapBack();
        }

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (to == pair && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (from == pair && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
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
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devWallet,
            block.timestamp
        );
    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;

        (success, ) = address(devWallet).call{value: ethForDev}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    modifier lockTheSwap() {
        _swapping = true;
        _;
        _swapping = false;
    }
}