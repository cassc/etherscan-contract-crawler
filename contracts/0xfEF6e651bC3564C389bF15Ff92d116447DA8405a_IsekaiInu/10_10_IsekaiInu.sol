// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract IsekaiInu is ERC20, Ownable {
    string private _name = "IsekaiInu";
    string private _symbol = "ISEKAI";
    uint8 private _decimals = 18;
    uint256 private _supply = 10000000000; // 10 Billion

    uint256 public buyTaxTreasury = 3;
    uint256 public sellTaxTreasury = 3;
    uint256 public buyTaxLiquidity = 1;
    uint256 public sellTaxLiquidity = 1;

    uint256 public maxTxAmount = 200000000 * 10**_decimals; // 2%
    uint256 public maxWalletAmount = 200000000 * 10**_decimals; // 2%

    address public devWallet = 0x981baf82d74AFc2D0d4A8A4e0bf589398cbb013F;
    address public marketingWallet = 0x7d852DC4168F6E8dfC98b31Eb6186F125bC12bb1;
    address public treasuryWallet = 0x2d3cDB10113c076da001a75F25603119DBca8a95;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 private _treasuryTaxCollected = 0;
    uint256 private _tokensLiqThreshold = 100000000 * 10**_decimals; // 1%
    uint256 private _tokensSwapThreshold = 20000000 * 10**_decimals; // 0.2%

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxLimits;

    bool public limitsInEffect = true;
    bool public tradingActive = false;

    bool inSwapping;

    // swap token for eth
    event SwapToken(uint256 tokenAmount, uint256 ethAmount);

    // swap then add to liquidity
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier swapLock() {
        inSwapping = true;
        _;
        inSwapping = false;
    }

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, (_supply * 10**_decimals));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[devWallet] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[treasuryWallet] = true;

        _isExcludedMaxLimits[address(uniswapV2Router)] = true;
        _isExcludedMaxLimits[address(uniswapV2Pair)] = true;
        _isExcludedMaxLimits[msg.sender] = true;
        _isExcludedMaxLimits[address(this)] = true;
        _isExcludedMaxLimits[devWallet] = true;
        _isExcludedMaxLimits[marketingWallet] = true;
        _isExcludedMaxLimits[treasuryWallet] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(balanceOf(from) >= amount, "Transfer amount exceeds balance");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingActive) {
            require(
                (_isExcludedFromFees[from] || _isExcludedFromFees[to]),
                "Trading/Sale is not yet active."
            );
        }
        if (limitsInEffect) {
            if ((from != owner() && to != owner()) && !inSwapping) {
                // at launch transfer delay (only on buys + transfers)
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                (block.number - 2),
                            "_transfer:: Transfer Delay enabled. Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                // Buy
                if (from == uniswapV2Pair) {
                    if (!_isExcludedMaxLimits[to]) {
                        require(
                            amount <= maxTxAmount,
                            "Buy transfer amount exceeds the maxTxAmount."
                        );
                        require(
                            amount + balanceOf(to) <= maxWalletAmount,
                            "Max wallet exceeded on Buy."
                        );
                    }
                } else if (to == uniswapV2Pair) {
                    if (!_isExcludedMaxLimits[from]) {
                        require(
                            amount <= maxTxAmount,
                            "Sell transfer amount exceeds the maxTxAmount."
                        );
                    }
                } else {
                    if (
                        !_isExcludedMaxLimits[from] && !_isExcludedMaxLimits[to]
                    ) {
                        require(
                            amount + balanceOf(to) <= maxWalletAmount,
                            "Max wallet exceeded on normal Transfer."
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= _tokensSwapThreshold;
        if (
            canSwap &&
            !inSwapping &&
            from != uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            uint256 contractLiquidityBalance = balanceOf(address(this)) -
                _treasuryTaxCollected;
            if (contractLiquidityBalance >= _tokensLiqThreshold) {
                _swapAndLiquify(_tokensLiqThreshold);
            }
            if (_treasuryTaxCollected >= _tokensSwapThreshold) {
                _swapTokensForEth(_tokensSwapThreshold);
                _treasuryTaxCollected -= _tokensSwapThreshold;
                bool sent = payable(treasuryWallet).send(address(this).balance);
                require(sent, "Failed to send tax ETH.");
            }
        }

        bool takeFee = !inSwapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        // Fees on Buy/Sell only
        if (takeFee) {
            uint256 fees = 0;
            uint256 treasuryShare = 0;

            if (to == uniswapV2Pair) {
                if (sellTaxLiquidity > 0) {
                    fees += (amount * sellTaxLiquidity) / 100;
                }
                if (sellTaxTreasury > 0) {
                    treasuryShare = (amount * sellTaxTreasury) / 100;
                    fees += treasuryShare;
                }
            } else if (from == uniswapV2Pair) {
                if (buyTaxLiquidity > 0) {
                    fees += (amount * buyTaxLiquidity) / 100;
                }
                if (buyTaxTreasury > 0) {
                    treasuryShare = (amount * buyTaxTreasury) / 100;
                    fees += treasuryShare;
                }
            }

            if (fees > 0) {
                if (treasuryShare > 0) {
                    _treasuryTaxCollected += treasuryShare;
                }
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapAndLiquify(uint256 tokenAmount) private swapLock {
        uint256 half = (tokenAmount / 2);
        uint256 otherHalf = (tokenAmount - half);

        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(half);

        uint256 swapETHAmount = address(this).balance - initialETHBalance;

        _addLiquidity(otherHalf, swapETHAmount);

        emit SwapAndLiquify(half, swapETHAmount, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private swapLock {
        uint256 originalETHAmount = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp + 180)
        );

        uint256 offsetETHAmount = address(this).balance - originalETHAmount;
        emit SwapToken(tokenAmount, offsetETHAmount);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        swapLock
    {
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

    function updateTrading(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
    }

    function updateLimits(bool _limitsInEffect) external onlyOwner {
        limitsInEffect = _limitsInEffect;
    }

    function updateTransferDelay(bool _transferDelayEnabled)
        external
        onlyOwner
    {
        transferDelayEnabled = _transferDelayEnabled;
    }

    function updateWallets(
        address newDev,
        address newMarketing,
        address newTreasury
    ) public onlyOwner {
        if (devWallet != newDev) {
            _isExcludedFromFees[devWallet] = false;
            _isExcludedMaxLimits[devWallet] = false;
            _isExcludedFromFees[newDev] = true;
            _isExcludedMaxLimits[newDev] = true;

            devWallet = newDev;
        }

        if (marketingWallet != newMarketing) {
            _isExcludedFromFees[marketingWallet] = false;
            _isExcludedMaxLimits[marketingWallet] = false;
            _isExcludedFromFees[newMarketing] = true;
            _isExcludedMaxLimits[newMarketing] = true;

            marketingWallet = newMarketing;
        }

        if (treasuryWallet != newTreasury) {
            _isExcludedFromFees[treasuryWallet] = false;
            _isExcludedMaxLimits[treasuryWallet] = false;
            _isExcludedFromFees[newTreasury] = true;
            _isExcludedMaxLimits[newTreasury] = true;

            treasuryWallet = newTreasury;
        }
    }

    function updateBuySellTax(
        uint256 newBuyTreasury,
        uint256 newSellTreasury,
        uint256 newBuyLiq,
        uint256 newSellLiq
    ) public onlyOwner {
        require(newBuyTreasury <= 5, "Buy treasury tax cannot exceed 5.");
        require(newSellTreasury <= 5, "Sell treasury tax cannot exceed 5.");
        require(newBuyLiq <= 5, "Buy liq tax cannot exceed 5.");
        require(newSellLiq <= 5, "Sell liq tax cannot exceed 5.");

        buyTaxTreasury = newBuyTreasury;
        sellTaxTreasury = newSellTreasury;
        buyTaxLiquidity = newBuyLiq;
        sellTaxLiquidity = newSellLiq;
    }

    function updateMaxTxAmount(uint256 newMaxAmount) public onlyOwner {
        require(newMaxAmount >= 1, "Max tx amount must be at least 1.");
        maxTxAmount = (totalSupply() * newMaxAmount) / 100;
    }

    function updateMaxWalletAmount(uint256 newMaxAmount) public onlyOwner {
        require(newMaxAmount >= 1, "Max wallet amount must be at least 1.");
        maxWalletAmount = (totalSupply() * newMaxAmount) / 100;
    }

    receive() external payable {}
}