/*

#####################################
Token generated with ❤️ on 20lab.app
#####################################

*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./Mintable.sol";
import "./TokenRecover.sol";
import "./CoinDividendTracker.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract TigPhantCoin is ERC20, ERC20Burnable, Ownable, Mintable, TokenRecover, DividendTrackerFunctions {
    
    uint256 public swapThreshold;
    
    uint256 private _tpcPending;
    uint256 private _liquidityPending;
    uint256 private _rewardsPending;

    address public tpcAddress;
    uint16[3] public tpcFees;

    uint16[3] public autoBurnFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    uint16[3] public rewardsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxTransferAmount;

    mapping (address => uint256) public lastTrade;
    uint256 public tradeCooldownTime;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event tpcAddressUpdated(address tpcAddress);
    event tpcFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event tpcFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
    event MaxTransferAmountUpdated(uint256 maxTransferAmount);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);
 
    constructor()
        ERC20(unicode"TigPhantCoin", unicode"TPC") 
        Mintable(5000000000000000)
    {
        address supplyRecipient = 0xc26f4Ac6aC441e7f2542F3105d3bd35380d29b7C;
        
        updateSwapThreshold(1650000000000 * (10 ** decimals()));

        tpcAddressSetup(0x5089c6faC7b8044fDD187B882C6E7C0da38c1396);
        tpcFeesSetup(200, 200, 200);

        autoBurnFeesSetup(200, 200, 200);

        lpTokensReceiverSetup(0x0000000000000000000000000000000000000000);
        liquidityFeesSetup(200, 200, 200);

        _deployDividendTracker(7200, 1000000000000 * (10 ** decimals()));

        gasForProcessingSetup(300000);
        rewardsFeesSetup(300, 300, 300);
        excludeFromDividends(supplyRecipient, true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(tpcAddress, true);

        updateMaxWalletAmount(1000000000000 * (10 ** decimals()));

        updateMaxBuyAmount(10000000000000 * (10 ** decimals()));
        updateMaxSellAmount(10000000000 * (10 ** decimals()));
        updateMaxTransferAmount(20000000000 * (10 ** decimals()));

        updateTradeCooldownTime(180);

        _mint(supplyRecipient, 3300000000000000 * (10 ** decimals()));
        _transferOwnership(0x5089c6faC7b8044fDD187B882C6E7C0da38c1396);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);

        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function getAllPending() public view returns (uint256) {
        return 0 + _tpcPending + _liquidityPending + _rewardsPending;
    }

    function tpcAddressSetup(address _newAddress) public onlyOwner {
        tpcAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit tpcAddressUpdated(_newAddress);
    }

    function tpcFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        tpcFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + tpcFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + tpcFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + tpcFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit tpcFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + tpcFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + tpcFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + tpcFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
        emit autoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns (uint256 leftover) {
        // Sub-optimal method for supplying liquidity
        uint256 halfAmount = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - halfAmount;

        _swapTokensForCoin(halfAmount);

        uint256 coinBalance = address(this).balance;

        if (coinBalance > 0) {
            (uint amountToken, uint amountCoin, uint liquidity) = _addLiquidity(otherHalf, coinBalance);

            emit liquidityAdded(amountToken, amountCoin, liquidity);

            return otherHalf - amountToken;
        } else {
            return otherHalf;
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 coinAmount) private returns (uint, uint, uint) {
        _approve(address(this), address(routerV2), tokenAmount);

        return routerV2.addLiquidityETH{value: coinAmount}(address(this), tokenAmount, 0, 0, lpTokensReceiver, block.timestamp);
    }

    function lpTokensReceiverSetup(address _newAddress) public onlyOwner {
        lpTokensReceiver = _newAddress;

        emit LpTokensReceiverUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        liquidityFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + tpcFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + tpcFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + tpcFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _sendDividends(uint256 tokenAmount) private {
        _swapTokensForCoin(tokenAmount);

        uint256 dividends = address(this).balance;
        
        if (dividends > 0) {
            (bool success,) = payable(address(dividendTracker)).call{value: dividends}("");
            if(success) emit rewardsFeeSent(dividends);
        }
    }

    function excludeFromDividends(address account, bool isExcluded) public override onlyOwner {
        dividendTracker.excludeFromDividends(account, balanceOf(account), isExcluded);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        rewardsFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + tpcFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + tpcFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + tpcFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
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
        
        bool canSwap = getAllPending() >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _tpcPending > 0) {
                uint256 token2Swap = 0 + _tpcPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 tpcPortion = coinsReceived * _tpcPending / token2Swap;
                if (tpcPortion > 0) {
                    (success,) = payable(address(tpcAddress)).call{value: tpcPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit tpcFeeSent(tpcAddress, tpcPortion);
                }
                _tpcPending = 0;

            }

            if (_liquidityPending > 0) {
                _swapAndLiquify(_liquidityPending);
                _liquidityPending = 0;
            }

            if (_rewardsPending > 0 && getNumberOfDividendTokenHolders() > 0) {
                _sendDividends(_rewardsPending);
                _rewardsPending = 0;
            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
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
                
                uint256 autoBurnPortion = 0;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _tpcPending += fees * tpcFees[txType] / totalFees[txType];

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

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromDividends(router, true);

        excludeFromLimits(router, true);

        _setAMMPair(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != pairV2, "DefaultRouter: Cannot remove initial pair from list");

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

    function updateMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function updateMaxTransferAmount(uint256 _maxTransferAmount) public onlyOwner {
        maxTransferAmount = _maxTransferAmount;
        
        emit MaxTransferAmountUpdated(_maxTransferAmount);
    }

    function updateTradeCooldownTime(uint256 _tradeCooldownTime) public onlyOwner {
        require(_tradeCooldownTime <= 7 days, "Antibot: Trade cooldown too long.");
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (AMMPairs[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        if (!AMMPairs[to] && !isExcludedFromLimits[from]) { // OTHER
            require(amount <= maxTransferAmount, "MaxTx: Cannot exceed max transfer limit");
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