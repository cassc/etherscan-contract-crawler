// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/**
 * @title First
 * @author ben.eth https://twitter.com/eth_ben
 * @notice First is First. Check it: https://twitter.com/eth_ben/status/1672187975680266242
 * @notice Join spaces here: https://twitter.com/eth_ben/status/1672155338697764864
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

IUniswapV2Router02 constant UNISWAP_ROUTER = IUniswapV2Router02(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
);

contract First is ERC20("First", "FIRST"), Ownable {
    uint256 public constant TOTAL_SUPPLY = 210_210_172 ether;

    address public immutable UNISWAP_PAIR;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 public swapTokensAtAmount;
    address public treasuryAddress;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyTreasuryFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellTreasuryFee;
    uint256 public sellLiquidityFee;

    uint256 public tokensForTreasury;
    uint256 public tokensForLiquidity;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    bool private _swapping;

    constructor() {
        UNISWAP_PAIR = IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = (TOTAL_SUPPLY * 10) / 1000;
        maxSellAmount = (TOTAL_SUPPLY * 10) / 1000;
        maxWalletAmount = (TOTAL_SUPPLY * 10) / 1000;
        swapTokensAtAmount = (TOTAL_SUPPLY * 50) / 100000;

        buyTreasuryFee = 2;
        buyLiquidityFee = 1;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee;

        sellTreasuryFee = 2;
        sellLiquidityFee = 1;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee;

        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);

        treasuryAddress = msg.sender;

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), type(uint256).max);
    }

    receive() external payable {}

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.1%"
        );
        maxBuyAmount = newNum * (10 ** 18);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.1%"
        );
        maxSellAmount = newNum * (10 ** 18);
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        if (!isEx) {
            require(
                updAds != UNISWAP_PAIR,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum * (10 ** 18);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function updateBuyFees(
        uint256 _treasuryFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        buyTreasuryFee = _treasuryFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateSellFees(
        uint256 _treasuryFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        sellTreasuryFee = _treasuryFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee;
        require(sellTotalFees <= 30, "Must keep fees at 30% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot re enable trading");
        tradingActive = true;
    }

    function setTreasuryAddress(address _TreasuryAddress) external onlyOwner {
        require(
            _TreasuryAddress != address(0),
            "_TreasuryAddress address cannot be 0"
        );
        treasuryAddress = payable(_TreasuryAddress);
    }

    function claimStuckTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            payable(treasuryAddress).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(treasuryAddress, balance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] ||
                            _isExcludedMaxTransactionAmount[to],
                        "Trading is not active."
                    );
                    require(from == owner(), "Trading is enabled");
                }

                //when buy
                if (
                    UNISWAP_PAIR == from && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyAmount,
                        "Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot Exceed max wallet"
                    );
                }
                //when sell
                else if (
                    UNISWAP_PAIR == to && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxSellAmount,
                        "Sell transfer amount exceeds the max sell."
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot Exceed max wallet"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !_swapping &&
            !(UNISWAP_PAIR == from) &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            _swapBack();
            _swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on Trades, not on wallet transfers

        if (takeFee) {
            // on sell
            if (UNISWAP_PAIR == to && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
            }
            // on buy
            else if (UNISWAP_PAIR == from && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // add the liquidity
        UNISWAP_ROUTER.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(treasuryAddress),
            block.timestamp
        );
    }

    function _swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForTreasury;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;

        _swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForTreasury = (ethBalance * tokensForTreasury) /
            (totalTokensToSwap - (tokensForLiquidity / 2));

        ethForLiquidity -= ethForTreasury;

        tokensForLiquidity = 0;
        tokensForTreasury = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success, ) = address(treasuryAddress).call{
            value: address(this).balance
        }("");
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        // make the swap
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}