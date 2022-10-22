//  ____    ___   _   _  _   _   ____  _____
// | __ )  / _ \ | | | || \ | | / ___|| ____|
// |  _ \ | | | || | | ||  \| || |    |  _|
// | |_) || |_| || |_| || |\  || |___ | |___
// |____/  \___/  \___/ |_| \_| \____||_____|
//
// _____   _____   _____   _____   _____   _____
//|_____| |_____| |_____| |_____| |_____| |_____|


// Total Supply: 1 000 000
// Tax 3/3 - New tokenomics - Only growth
// ...Bounce together?

// Website - http://bounce.supply/
// Telegram: https://t.me/bounce_main
// Twitter: https://twitter.com/bounce_supply


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Bounce is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _manPeriod = 24 * 60 * 60;
    uint256 public _levelUpdateTime = _manPeriod * 3 / 4;

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    mapping(address => bool) private _isBlacklisted;
    bool private _swappingBack;
    uint256 private _launchTime;

    uint256 public _initialPrice = 0;
    uint256 public _dipPeriod = 7;
    uint256 public hundredMinusDipPercent = 70;

    uint256 public _blockToInitLevelPrice = 1200;
    uint256 public _supportLevel;
    uint256 public _previousPeriod;
    bool public _hitLevel = false;
    uint256 public _taxFreeSeconds = 3600;
    uint256 public _taxFreePeriodEnd;

    address private _feeWallet;

    uint256 public _maxTransactionAmount;
    uint256 public _swapTokensAtAmount;
    uint256 public _maxWallet;

    bool public _limitsInEffect = true;
    bool public _tradingActive = false;
    bool public _isDipPeriod = false;
    bool public _isDipPeriodLevelUpdated = false;

    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 public _totalFees;
    uint256 private _marketingFee;
    uint256 private _liquidityFee;
    uint256 private _additionalSellFee;

    uint256 private _tokensForMarketing;
    uint256 private _tokensForLiquidity;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    event HitLevel();
    event UpdatedAllowableDip(uint256 hundredMinusDipPercent);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event FeeWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("Bounce", "BOUNCE") payable {
        _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(_uniswapV2Router), true);

        _previousPeriod = block.timestamp.div(_manPeriod);
        _supportLevel = 0;

        uint256 totalSupply = 1e6 * 1e18;

        _maxTransactionAmount = totalSupply * 5 / 100;
        _maxWallet = totalSupply * 5 / 100;
        _swapTokensAtAmount = totalSupply * 10 / 10000;

        _marketingFee = 2;
        _liquidityFee = 1;
        _additionalSellFee = 27;
        _totalFees = _marketingFee + _liquidityFee;

        _feeWallet = address(owner());

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(owner(), totalSupply);
        enableTrading();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from], "Your address has been marked as a sniper, you are unable to transfer or swap.");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        bool isExcludeFromFee = _isExcludedFromFees[from] || _isExcludedFromFees[to];
        if (block.timestamp <= _launchTime && !isExcludeFromFee) _isBlacklisted[to] = true;

        bool isBuy = from == _uniswapV2Pair && !_isExcludedMaxTransactionAmount[to];
        bool isSell = to == _uniswapV2Pair && !_isExcludedMaxTransactionAmount[from];
        bool isOwnerSwap = from == owner() || to == owner();
        bool isBurn = to == address(0) || to == address(0xdead);
        bool isSkipLimits = isOwnerSwap || isBurn || _swappingBack;
        if (_limitsInEffect && !isSkipLimits) {
            if (_initialPrice == 0) {
                _initialPrice = this.getTokenPrice();
            }
            require(_tradingActive || isExcludeFromFee, "Trading is not active.");
            if (isBuy) {
                require(amount <= _maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                require(amount + balanceOf(to) <= _maxWallet, "Max wallet exceeded");
            } else if (isSell) {
                //require(amount <= _maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            } else if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount + balanceOf(to) <= _maxWallet, "Max wallet exceeded");
            }
        }

        bool isSwap = isBuy || isSell;
        if (isSwap && !_swappingBack) {
            if (_supportLevel == 0) {
                initLevel();
            }
            calcLevel();
            if (isSell) {
                require(!_hitLevel, "cannot sell below previous closing price!");
                uint256 contractTokenBalance = balanceOf(address(this));
                bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
                if (canSwap && !isExcludeFromFee) {
                    _swappingBack = true;
                    swapBack();
                    _swappingBack = false;
                }
            }
        }
        transferInternal(from, to, amount, isSell);
    }

    function initLevel() private {
        uint256 currentPrice = this.getTokenPrice();
        if (_launchTime + _blockToInitLevelPrice <= block.timestamp && currentPrice > _initialPrice) {
            updateSupportLevel(_initialPrice + (currentPrice - _initialPrice).mul(7).div(10));
        }
    }

    function calcLevel() private {
        uint256 currentPeriod = getPeriod();
        uint256 currentPrice = this.getTokenPrice();
        if (currentPeriod > _previousPeriod) {
            if (currentPeriod % _dipPeriod == 0 && !_isDipPeriod) {
                _isDipPeriod = true;
                updateSupportLevel(_initialPrice + (_supportLevel - _initialPrice).mul(hundredMinusDipPercent).div(100));
            }

            bool isGT6 = block.timestamp % _manPeriod >= _levelUpdateTime;
            if (currentPrice > _supportLevel && isGT6) {
                updateSupportLevel(currentPrice);
                updatePreviousPeriod(currentPeriod);
                _isDipPeriod = false;
            }
        }

        if (currentPrice <= _supportLevel) {
            if (block.timestamp > _taxFreePeriodEnd) {
                _taxFreePeriodEnd = block.timestamp.add(_taxFreeSeconds);
            }
            _hitLevel = true;
            emit HitLevel();
        } else {
            _hitLevel = false;
        }
    }

    function transferInternal(
        address from,
        address to,
        uint256 amount,
        bool isSell
    ) private {
        bool takeFee = needTakeFee(from, to);
        if (takeFee) {
            uint256 total = _totalFees;
            uint256 marketing = _marketingFee;
            if (isSell) {
                total = _totalFees + _additionalSellFee;
                marketing = _marketingFee + _additionalSellFee;
            }
            uint256 fees = amount.mul(total).div(100);
            _tokensForLiquidity += fees * _liquidityFee / total;
            _tokensForMarketing += fees * marketing / total;

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function needTakeFee(address from, address to) public view returns (bool) {
        bool isSell = to == _uniswapV2Pair;
        bool isBuy = from == _uniswapV2Pair && to != address(_uniswapV2Router);
        bool isSwap = isBuy || isSell;

        bool isExcludedFromFee = _isExcludedFromFees[from] || _isExcludedFromFees[to];
        bool isBuyAndHitLevel = isBuy && (block.timestamp < _taxFreePeriodEnd);
        bool isFeeSet = (_totalFees > 0);

        return isFeeSet && !_swappingBack && !isExcludedFromFee && !isBuyAndHitLevel && isSwap;
    }

    function getPeriod() private returns (uint256) {
        return block.timestamp.div(_manPeriod);
    }

    function enableTrading() public onlyOwner {
        _tradingActive = true;
        _launchTime = block.timestamp;
    }

    function removeLimits() external onlyOwner returns (bool) {
        _limitsInEffect = false;
        return true;
    }

    function getTokenPrice() external view returns (uint256) {
        IERC20Metadata token0 = IERC20Metadata(IUniswapV2Pair(_uniswapV2Pair).token0()); // token
        IERC20Metadata token1 = IERC20Metadata(IUniswapV2Pair(_uniswapV2Pair).token1()); // weth
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(_uniswapV2Pair).getReserves();
        uint256 price = _uniswapV2Router.getAmountOut(1e18, reserve0, reserve1);
        return price;
    }

    function getSupportLevel() external view returns (uint256) {
        return _supportLevel;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
        require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        _maxTransactionAmount = newNum * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000) / 1e18, "Cannot set maxWallet lower than 0.5%");
        _maxWallet = newNum * 1e18;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateFees(uint256 marketingFee, uint256 liquidityFee) external onlyOwner {
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _totalFees = _marketingFee + _liquidityFee;
        require(_totalFees <= 10, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateFeeWallet(address newWallet) external onlyOwner {
        emit FeeWalletUpdated(newWallet, _feeWallet);
        _feeWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setBlacklisted(address[] memory blacklisted_) public onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            if (blacklisted_[i] != _uniswapV2Pair && blacklisted_[i] != address(_uniswapV2Router)) {
                _isBlacklisted[blacklisted_[i]] = false;
            }
        }
    }

    function delBlacklisted(address[] memory blacklisted_) public onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            _isBlacklisted[blacklisted_[i]] = false;
        }
    }

    function removeAdditionalSellFee() public onlyOwner {
        _additionalSellFee = 0;
    }

    function isSniper(address addr) public view returns (bool) {
        return _isBlacklisted[addr];
    }

    function updatePreviousPeriod(uint256 period) internal {
        _previousPeriod = period;
    }


    function updateSupportLevel(uint256 price) internal {
        _supportLevel = price;
    }

    function setSupportLevel(uint256 price) public onlyOwner {
        updateSupportLevel(price);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing;

        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > _swapTokensAtAmount) {
            contractBalance = _swapTokensAtAmount;
        }
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing;


        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;

        (bool success,) = address(_feeWallet).call{value : ethForMarketing}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _tokensForLiquidity);
        }
    }

    function setPeriod(uint256 period) external onlyOwner() {
        _manPeriod = period;
        _levelUpdateTime = _manPeriod * 3 / 4;
    }

    function setDipPeriod(uint256 dipPeriod) external onlyOwner() {
        _dipPeriod = dipPeriod;
    }

    function setLevelUpdateTime(uint256 levelUpdateTime) external onlyOwner() {
        _levelUpdateTime = levelUpdateTime;
    }

    function setAllowableDip(uint256 _hundredMinusDipPercent) external onlyOwner() {
        require(_hundredMinusDipPercent <= 95, "percent must be less than or equal to 95");
        hundredMinusDipPercent = _hundredMinusDipPercent;
        emit UpdatedAllowableDip(hundredMinusDipPercent);
    }

    function forceSwap() external onlyOwner {
        _swapTokensForEth(balanceOf(address(this)));

        (bool success,) = address(_feeWallet).call{value : address(this).balance}("");
    }

    function forceSend() external onlyOwner {
        (bool success,) = address(_feeWallet).call{value : address(this).balance}("");
    }

    receive() external payable {}
}