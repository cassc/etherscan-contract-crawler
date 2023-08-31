// SPDX-License-Identifier: MIT
// Factory: CreateMyToken
pragma solidity ^0.8.19;

import "./core/ERC20.sol";
import "./core/Initializable.sol";
import "./core/Ownable.sol";

import "./core/interfaces/uniswap/IUniswapV2Router02.sol";
import "./core/interfaces/uniswap/IUniswapV2Factory.sol";

uint256 constant DENOMINATOR = 100_00;

contract DeflationaryToken is Initializable, ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public maxWalletAmount;
    uint256 public maxTxAmount;

    uint256 public minimumTokensBeforeSwap;

    address private liquidityWallet;
    address private operationsWallet;
    address private burnWallet;

    struct FeeDataStorage {
        // Liquidity Fee
        uint8 liquidityFeeOnBuy;
        uint8 liquidityFeeOnSell;
        // Marketing/Operations Fee
        uint8 operationsFeeOnBuy;
        uint8 operationsFeeOnSell;
        // Burn Fee
        uint8 burnFeeOnBuy;
        uint8 burnFeeOnSell;
        // Apply fee on transfers?
        bool applyTaxOnTransfer;
    }

    // Base taxes
    FeeDataStorage public baseFeeData;

    mapping(address => bool) private _isBlocked;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;

    mapping(address => bool) public automatedMarketMakerPairs;

    // Emphemerals START
    bool private _swapping;

    uint8 private _liquidityFee;
    uint8 private _operationsFee;
    uint8 private _burnFee;
    uint8 private _totalFee;

    // Emphemerals END

    receive() external payable {}

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _routerV2,
        FeeDataStorage calldata baseTaxes,
        address liquidityWallet_,
        address operationsWallet_,
        address burnWallet_,
        uint256 maxWalletPct,
        uint256 maxTxPct
    ) external initializer {
        _transferOwnership(_owner);

        uint256 initialSupply = _initialSupply * (10 ** _decimals);

        ERC20.init(_name, _symbol, _decimals, initialSupply);

        maxWalletAmount = (initialSupply * maxWalletPct) / DENOMINATOR;
        maxTxAmount = (initialSupply * maxTxPct) / DENOMINATOR;
        minimumTokensBeforeSwap = (initialSupply) / (DENOMINATOR * 100); // 0.0001%

        baseFeeData = baseTaxes;

        liquidityWallet = liquidityWallet_;
        operationsWallet = operationsWallet_;
        burnWallet = burnWallet_;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerV2);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[_owner] = true;

        _mint(_owner, initialSupply);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TOKEN: Automated market maker pair is already set to that value"
        );

        automatedMarketMakerPairs[pair] = value;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "TOKEN: Account is already the value of 'excluded'");

        _isExcludedFromFee[account] = excluded;
    }

    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(
            _isExcludedFromMaxTransactionLimit[account] != excluded,
            "TOKEN: Account is already the value of 'excluded'"
        );

        _isExcludedFromMaxTransactionLimit[account] = excluded;
    }

    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(
            _isExcludedFromMaxWalletLimit[account] != excluded,
            "TOKEN: Account is already the value of 'excluded'"
        );

        _isExcludedFromMaxWalletLimit[account] = excluded;
    }

    function blockAccount(address account) external onlyOwner {
        require(!_isBlocked[account], "TOKEN: Account is already blocked");

        _isBlocked[account] = true;
    }

    function unblockAccount(address account) external onlyOwner {
        require(_isBlocked[account], "TOKEN: Account is not blcoked");

        _isBlocked[account] = false;
    }

    function setWallets(address newLiquidityWallet, address newOperationsWallet) external onlyOwner {
        if (liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "TOKEN: The liquidityWallet cannot be 0");
            liquidityWallet = newLiquidityWallet;
        }

        if (operationsWallet != newOperationsWallet) {
            require(newOperationsWallet != address(0), "TOKEN: The operationsWallet cannot be 0");
            operationsWallet = newOperationsWallet;
        }
    }

    function setFeesData(FeeDataStorage calldata taxData) external onlyOwner {
        require(
            (taxData.liquidityFeeOnBuy + taxData.operationsFeeOnBuy + taxData.burnFeeOnBuy) <= 25,
            "TOKEN: Tax exceeds maximum value of 30%"
        );
        require(
            (taxData.liquidityFeeOnSell + taxData.operationsFeeOnSell + taxData.burnFeeOnSell) <= 25,
            "TOKEN: Tax exceeds maximum value of 30%"
        );

        baseFeeData = taxData;
    }

    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "TOKEN: Cannot update maxTxAmount to same value");

        maxTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, "TOKEN: Cannot update maxWalletAmount to same value");

        maxWalletAmount = newValue;
    }

    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "TOKEN: Cannot update minimumTokensBeforeSwap to same value");

        minimumTokensBeforeSwap = newValue;
    }

    function claimETHOverflow() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = address(owner()).call{ value: amount }("");

        require(success);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];

        require(!_isBlocked[to], "TOKEN: Account is blocked");
        require(!_isBlocked[from], "TOKEN: Account is blocked");

        if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
            require(amount <= maxTxAmount, "TOKEN: Buy amount exceeds the maxTxBuyAmount.");
        }

        if (!_isExcludedFromMaxWalletLimit[to]) {
            require(
                (balanceOf(to) + amount) <= maxWalletAmount,
                "TOKEN: Expected wallet amount exceeds the maxWalletAmount."
            );
        }

        _adjustTaxes(isBuyFromLp, isSelltoLp);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (canSwap && !_swapping && _totalFee > 0 && isSelltoLp) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }

        super._transfer(from, to, amount);
    }

    function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
        _liquidityFee = 0;
        _operationsFee = 0;
        _burnFee = 0;

        if (isBuyFromLp) {
            _liquidityFee = baseFeeData.liquidityFeeOnBuy;
            _operationsFee = baseFeeData.operationsFeeOnBuy;
            _burnFee = baseFeeData.burnFeeOnBuy;
        }

        if (isSelltoLp) {
            _liquidityFee = baseFeeData.liquidityFeeOnSell;
            _operationsFee = baseFeeData.operationsFeeOnSell;
            _burnFee = baseFeeData.burnFeeOnSell;
        }

        if (!isSelltoLp && !isBuyFromLp && baseFeeData.applyTaxOnTransfer) {
            _liquidityFee = baseFeeData.liquidityFeeOnBuy;
            _operationsFee = baseFeeData.operationsFeeOnBuy;
            _burnFee = baseFeeData.burnFeeOnBuy;
        }

        _totalFee = _liquidityFee + _operationsFee + _burnFee;
    }

    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;

        uint8 _totalFeePrior = _totalFee;

        uint256 amountToLiquify = (contractBalance * _liquidityFee) / _totalFeePrior / 2;
        uint256 amountToSwap = contractBalance - amountToLiquify;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFeePrior - (_liquidityFee / 2);

        uint256 amountETHLiquidity = (ETHBalanceAfterSwap * _liquidityFee) / totalETHFee / 2;
        uint256 amountETHOperations = (ETHBalanceAfterSwap * _operationsFee) / totalETHFee;
        uint256 amountETHBurn = (ETHBalanceAfterSwap * _burnFee) / totalETHFee;

        Address.sendValue(payable(operationsWallet), amountETHOperations);
        Address.sendValue(payable(burnWallet), amountETHBurn);

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
        }

        _totalFee = _totalFeePrior;
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            1, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}

// Create your own token at https://www.createmytoken.com/