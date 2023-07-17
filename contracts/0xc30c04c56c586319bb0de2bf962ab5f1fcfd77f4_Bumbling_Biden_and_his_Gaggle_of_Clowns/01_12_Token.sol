/*
https://gaggleofclowns.com

Bumbling Biden and his Gaggle of Clowns
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./TokenRecover.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Bumbling_Biden_and_his_Gaggle_of_Clowns is ERC20, ERC20Burnable, Ownable, TokenRecover {
    
    uint256 public swapThreshold;
    
    uint256 private _rewardsPending;
    uint256 private _anticlownPending;
    uint256 private _marketingPending;
    uint256 private _liquidityPending;

    address public rewardsAddress;
    uint16[3] public rewardsFees;

    address public anticlownAddress;
    uint16[3] public anticlownFees;

    address public marketingAddress;
    uint16[3] public marketingFees;

    uint16[3] public autoBurnFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

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
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event rewardsAddressUpdated(address rewardsAddress);
    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(address recipient, uint256 amount);

    event anticlownAddressUpdated(address anticlownAddress);
    event anticlownFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event anticlownFeeSent(address recipient, uint256 amount);

    event marketingAddressUpdated(address marketingAddress);
    event marketingFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event marketingFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"Bumbling Biden and his Gaggle of Clowns", unicode"GOC") 
    {
        address supplyRecipient = 0x7AC8e16e55D839221B592DDc96E901B25429C7d5;
        
        updateSwapThreshold(1800000000 * (10 ** decimals()));

        rewardsAddressSetup(0xF2d45cddfC69EfA99B16714F071943c7242BcBf4);
        rewardsFeesSetup(150, 150, 0);

        anticlownAddressSetup(0xFfD8D9723f14839957F1B155F953F4Bb5FC44869);
        anticlownFeesSetup(150, 150, 0);

        marketingAddressSetup(0x8DA0376F2970AD311Aea0a56C38d71e33968e1D2);
        marketingFeesSetup(2000, 2000, 0);

        autoBurnFeesSetup(50, 50, 0);

        lpTokensReceiverSetup(0x0000000000000000000000000000000000000000);
        liquidityFeesSetup(50, 50, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(rewardsAddress, true);
        excludeFromLimits(anticlownAddress, true);
        excludeFromLimits(marketingAddress, true);

        updateMaxWalletAmount(1500000000 * (10 ** decimals()));

        updateMaxBuyAmount(1500000000 * (10 ** decimals()));
        updateMaxSellAmount(1500000000 * (10 ** decimals()));

        _mint(supplyRecipient, 47000000000 * (10 ** decimals()));
        _transferOwnership(0x7AC8e16e55D839221B592DDc96E901B25429C7d5);
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
        return 0 + _rewardsPending + _anticlownPending + _marketingPending + _liquidityPending;
    }

    function rewardsAddressSetup(address _newAddress) public onlyOwner {
        rewardsAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit rewardsAddressUpdated(_newAddress);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        rewardsFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + rewardsFees[0] + anticlownFees[0] + marketingFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + rewardsFees[1] + anticlownFees[1] + marketingFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + rewardsFees[2] + anticlownFees[2] + marketingFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit rewardsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function anticlownAddressSetup(address _newAddress) public onlyOwner {
        anticlownAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit anticlownAddressUpdated(_newAddress);
    }

    function anticlownFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        anticlownFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + rewardsFees[0] + anticlownFees[0] + marketingFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + rewardsFees[1] + anticlownFees[1] + marketingFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + rewardsFees[2] + anticlownFees[2] + marketingFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit anticlownFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function marketingAddressSetup(address _newAddress) public onlyOwner {
        marketingAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit marketingAddressUpdated(_newAddress);
    }

    function marketingFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        marketingFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + rewardsFees[0] + anticlownFees[0] + marketingFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + rewardsFees[1] + anticlownFees[1] + marketingFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + rewardsFees[2] + anticlownFees[2] + marketingFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit marketingFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + rewardsFees[0] + anticlownFees[0] + marketingFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + rewardsFees[1] + anticlownFees[1] + marketingFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + rewardsFees[2] + anticlownFees[2] + marketingFees[2] + autoBurnFees[2] + liquidityFees[2];
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

        totalFees[0] = 0 + rewardsFees[0] + anticlownFees[0] + marketingFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + rewardsFees[1] + anticlownFees[1] + marketingFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + rewardsFees[2] + anticlownFees[2] + marketingFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
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
            
            if (false || _rewardsPending > 0 || _anticlownPending > 0 || _marketingPending > 0) {
                uint256 token2Swap = 0 + _rewardsPending + _anticlownPending + _marketingPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 rewardsPortion = coinsReceived * _rewardsPending / token2Swap;
                if (rewardsPortion > 0) {
                    (success,) = payable(address(rewardsAddress)).call{value: rewardsPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit rewardsFeeSent(rewardsAddress, rewardsPortion);
                }
                _rewardsPending = 0;

                uint256 anticlownPortion = coinsReceived * _anticlownPending / token2Swap;
                if (anticlownPortion > 0) {
                    (success,) = payable(address(anticlownAddress)).call{value: anticlownPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit anticlownFeeSent(anticlownAddress, anticlownPortion);
                }
                _anticlownPending = 0;

                uint256 marketingPortion = coinsReceived * _marketingPending / token2Swap;
                if (marketingPortion > 0) {
                    (success,) = payable(address(marketingAddress)).call{value: marketingPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit marketingFeeSent(marketingAddress, marketingPortion);
                }
                _marketingPending = 0;

            }

            if (_liquidityPending > 0) {
                _swapAndLiquify(_liquidityPending);
                _liquidityPending = 0;
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
                
                _rewardsPending += fees * rewardsFees[txType] / totalFees[txType];

                _anticlownPending += fees * anticlownFees[txType] / totalFees[txType];

                _marketingPending += fees * marketingFees[txType] / totalFees[txType];

                if (autoBurnFees[txType] > 0) {
                    autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                    _burn(from, autoBurnPortion);
                    emit autoBurned(autoBurnPortion);
                }

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                fees = fees - autoBurnPortion;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
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
    
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (!isExcludedFromLimits[to]) {
            require(balanceOf(to) <= maxWalletAmount, "MaxWallet: Cannot exceed max wallet limit");
        }

        super._afterTokenTransfer(from, to, amount);
    }
}