/*
MEEEEEWWWN 
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./Mintable.sol";
import "./Pausable.sol";
import "./TokenRecover.sol";
import "./CoinDividendTracker.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Mewn is ERC20, ERC20Burnable, Ownable, Mintable, Pausable, TokenRecover, DividendTrackerFunctions {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _taxxxPending;
    uint256 private _taxxxxPending;
    uint256 private _liquidityPending;
    uint256 private _rewardsPending;

    address public taxxxAddress;
    uint16[3] public taxxxFees;

    address public taxxxxAddress;
    uint16[3] public taxxxxFees;

    uint16[3] public autoBurnFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    uint16[3] public rewardsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxTxAmount;

    mapping (address => uint256) public lastTrade;
    uint256 public tradeCooldownTime;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event taxxxAddressUpdated(address taxxxAddress);
    event taxxxFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event taxxxFeeSent(address recipient, uint256 amount);

    event taxxxxAddressUpdated(address taxxxxAddress);
    event taxxxxFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event taxxxxFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountETH, uint liquidity);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UniswapV2RouterUpdated(address indexed uniswapV2Router);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxTxAmountUpdated(uint256 maxTxAmount);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);
 
    constructor()
        ERC20("Mewn", "Moon") 
        Mintable(999999)
    {
        address supplyRecipient = 0x25AcFE0Be86A16d91EB65c92ECF3088bBdE8dB09;
        
        updateSwapThreshold(5 * (10 ** decimals()));

        taxxxAddressSetup(0x0D89b1ed92852b7fB1C667E0B69F8caD2EB67963);
        taxxxFeesSetup(130, 160, 170);

        taxxxxAddressSetup(0x133b8288F54755684AE70cAcB2F2e50e58d4e5d2);
        taxxxxFeesSetup(600, 700, 800);

        autoBurnFeesSetup(150, 250, 350);

        lpTokensReceiverSetup(0x0000000000000000000000000000000000000000);
        liquidityFeesSetup(450, 550, 650);

        _deployDividendTracker(1380, 2020 * (10 ** decimals()));

        gasForProcessingSetup(300000);
        rewardsFeesSetup(110, 220, 330);
        excludeFromDividends(supplyRecipient, true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(taxxxAddress, true);
        excludeFromLimits(taxxxxAddress, true);

        updateMaxWalletAmount(6969 * (10 ** decimals()));

        updateMaxTxAmount(1313 * (10 ** decimals()));

        updateTradeCooldownTime(4620);

        _mint(supplyRecipient, 10000 * (10 ** decimals()));
        _transferOwnership(0xa9B37059d667b24c1641822d6cc70C014d15784d);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function blacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;

        emit BlacklistUpdated(account, isBlacklisted);
    }

    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function taxxxAddressSetup(address _newAddress) public onlyOwner {
        taxxxAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit taxxxAddressUpdated(_newAddress);
    }

    function taxxxFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        taxxxFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + taxxxFees[0] + taxxxxFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + taxxxFees[1] + taxxxxFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + taxxxFees[2] + taxxxxFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit taxxxFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function taxxxxAddressSetup(address _newAddress) public onlyOwner {
        taxxxxAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit taxxxxAddressUpdated(_newAddress);
    }

    function taxxxxFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        taxxxxFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + taxxxFees[0] + taxxxxFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + taxxxFees[1] + taxxxxFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + taxxxFees[2] + taxxxxFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit taxxxxFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + taxxxFees[0] + taxxxxFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + taxxxFees[1] + taxxxxFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + taxxxFees[2] + taxxxxFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
        emit autoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns (uint256 leftover) {
        // Sub-optimal method for supplying liquidity
        uint256 halfAmount = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - halfAmount;

        _swapTokensForCoin(halfAmount);

        uint256 coinBalance = address(this).balance;

        (uint amountToken, uint amountETH, uint liquidity) = _addLiquidity(otherHalf, coinBalance);

        emit liquidityAdded(amountToken, amountETH, liquidity);

        return otherHalf - amountToken;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private returns (uint, uint, uint) {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        return uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, lpTokensReceiver, block.timestamp);
    }

    function lpTokensReceiverSetup(address _newAddress) public onlyOwner {
        lpTokensReceiver = _newAddress;

        emit LpTokensReceiverUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        liquidityFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + taxxxFees[0] + taxxxxFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + taxxxFees[1] + taxxxxFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + taxxxFees[2] + taxxxxFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _sendDividends(uint256 tokenAmount) private {
        _swapTokensForCoin(tokenAmount);

        uint256 dividends = address(this).balance;
        (bool success,) = payable(address(dividendTracker)).call{value: dividends}("");

        if(success) emit rewardsFeeSent(dividends);
    }

    function excludeFromDividends(address account, bool isExcluded) public override onlyOwner {
        dividendTracker.excludeFromDividends(account, balanceOf(account), isExcluded);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        rewardsFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + taxxxFees[0] + taxxxxFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + taxxxFees[1] + taxxxxFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + taxxxFees[2] + taxxxxFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
        emit rewardsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        
        dividendTracker.setBalance(account, balanceOf(account));
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        
        dividendTracker.setBalance(account, balanceOf(account));
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        bool canSwap = 0 + _taxxxPending + _taxxxxPending + _liquidityPending + _rewardsPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _taxxxPending > 0 || _taxxxxPending > 0) {
                uint256 token2Swap = 0 + _taxxxPending + _taxxxxPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 taxxxPortion = coinsReceived * _taxxxPending / token2Swap;
                (success,) = payable(address(taxxxAddress)).call{value: taxxxPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit taxxxFeeSent(taxxxAddress, taxxxPortion);
                _taxxxPending = 0;

                uint256 taxxxxPortion = coinsReceived * _taxxxxPending / token2Swap;
                (success,) = payable(address(taxxxxAddress)).call{value: taxxxxPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit taxxxxFeeSent(taxxxxAddress, taxxxxPortion);
                _taxxxxPending = 0;

            }

            if (_liquidityPending > 0) {
                _liquidityPending = _swapAndLiquify(_liquidityPending);
            }

            if (_rewardsPending > 0 && getNumberOfDividendTokenHolders() > 0) {
                _sendDividends(_rewardsPending);
                _rewardsPending = 0;
            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(uniswapV2Router) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (AMMPairs[from]) {
                if (totalFees[0] > 0) txType = 0;
            }
            else if (AMMPairs[to]) {
                if (totalFees[1] > 0) txType = 1;
            }
            else if (totalFees[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                uint256 autoBurnPortion;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _taxxxPending += fees * taxxxFees[txType] / totalFees[txType];

                _taxxxxPending += fees * taxxxxFees[txType] / totalFees[txType];

                if (autoBurnFees[txType] > 0) {
                    autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                    _burn(from, autoBurnPortion);
                    emit autoBurned(autoBurnPortion);
                }

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                _rewardsPending += fees * rewardsFees[txType] / totalFees[txType];

                fees = fees - autoBurnPortion;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
        dividendTracker.setBalance(from, balanceOf(from));
        dividendTracker.setBalance(to, balanceOf(to));
        
        if (!_swapping) try dividendTracker.process(gasForProcessing) {} catch {}

    }

    function _updateUniswapV2Router(address router) private {
        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
        excludeFromDividends(router, true);

        excludeFromLimits(router, true);

        _setAMMPair(uniswapV2Pair, true);

        emit UniswapV2RouterUpdated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != uniswapV2Pair, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        AMMPairs[pair] = isPair;

        if (isPair) { 
            excludeFromDividends(pair, true);

            excludeFromLimits(pair, true);

        }

        emit AMMPairsUpdated(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function updateMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        maxWalletAmount = _maxWalletAmount;
        
        emit MaxWalletAmountUpdated(_maxWalletAmount);
    }

    function updateMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = _maxTxAmount;
        
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function updateTradeCooldownTime(uint256 _tradeCooldownTime) public onlyOwner {
        require(_tradeCooldownTime <= 7 days, "Antibot: Trade cooldown too long.");
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(!blacklisted[from] && !blacklisted[to], "Blacklist: Sender or recipient is blacklisted");

        if (AMMPairs[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        if (!AMMPairs[to] && !isExcludedFromLimits[from]) { // OTHER
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max transfer limit");
        }
    
        if(!isExcludedFromLimits[from])
            require(lastTrade[from] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction sender is in anti-bot cooldown");
        if(!isExcludedFromLimits[to])
            require(lastTrade[to] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction recipient is in anti-bot cooldown");

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (!isExcludedFromLimits[to]) {
            require(balanceOf(to) <= maxWalletAmount, "MaxWallet: Cannot exceed max wallet limit");
        }

        if (AMMPairs[from] && !isExcludedFromLimits[to]) lastTrade[to] = block.timestamp;
        else if (AMMPairs[to] && !isExcludedFromLimits[from]) lastTrade[from] = block.timestamp;

        super._afterTokenTransfer(from, to, amount);
    }
}