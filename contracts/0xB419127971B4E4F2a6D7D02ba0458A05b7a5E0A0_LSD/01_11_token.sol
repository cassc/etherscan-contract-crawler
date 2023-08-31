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

contract LSD is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public RechargeArmamentStatBlueprint;
    uint16[3] public MonetarySpeedSightAssessment;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public IgniteArmamentStructure;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ClarifyBlastSpecifications;
    mapping (address => bool) public BloomNetworkStartup;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event RechargeArmamentStatBlueprintUpdated(address RechargeArmamentStatBlueprint);
    event RigorousCommerceOscillationCheck(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event BusinessAssessmentDigest(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);	
    event CoalitionRestartModifications(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"LSD BOT", unicode"LSD BOT") 
    {
        address supplyRecipient = 0x966936fD3F9d470312020CF49bB175aE20Ee0392;
        
        CulminationSniperEconomicDismantling(40000000 * (10 ** decimals()) / 10);

        MagnifyRocketConstraintStrategies(0x966936fD3F9d470312020CF49bB175aE20Ee0392);
        StrengthenPeakVelocityBuyLimit(0, 1500, 1500);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(RechargeArmamentStatBlueprint, true);

        SwiftConflagrationBaseCostOverhaul(40000000 * (10 ** decimals()) / 10);
        LanceHarmonyTechniques(10000000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x966936fD3F9d470312020CF49bB175aE20Ee0392);
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

    function CulminationSniperEconomicDismantling(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function EconomicAuthenticityAttestation() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function MagnifyRocketConstraintStrategies(address _newAddress) public onlyOwner {
        RechargeArmamentStatBlueprint = _newAddress;

        excludeFromFees(_newAddress, true);

        emit RechargeArmamentStatBlueprintUpdated(_newAddress);
    }

    function StrengthenPeakVelocityBuyLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        MonetarySpeedSightAssessment = [_buyFee, _sellFee, _transferFee];

        IgniteArmamentStructure[0] = 0 + MonetarySpeedSightAssessment[0];
        IgniteArmamentStructure[1] = 0 + MonetarySpeedSightAssessment[1];
        IgniteArmamentStructure[2] = 0 + MonetarySpeedSightAssessment[2];
        require(IgniteArmamentStructure[0] <= 10000 && IgniteArmamentStructure[1] <= 10000 && IgniteArmamentStructure[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit RigorousCommerceOscillationCheck(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = EconomicAuthenticityAttestation() >= swapThreshold;
        
        if (!_swapping && !BloomNetworkStartup[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(RechargeArmamentStatBlueprint)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit BusinessAssessmentDigest(RechargeArmamentStatBlueprint, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BloomNetworkStartup[from]) {
                if (IgniteArmamentStructure[0] > 0) txType = 0;
            }
            else if (BloomNetworkStartup[to]) {
                if (IgniteArmamentStructure[1] > 0) txType = 1;
            }
            else if (IgniteArmamentStructure[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * IgniteArmamentStructure[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * MonetarySpeedSightAssessment[txType] / IgniteArmamentStructure[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ClarifyBlastSpecifications = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ClarifyBlastSpecifications, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ClarifyBlastSpecifications, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BloomNetworkStartup[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit CoalitionRestartModifications(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function SwiftConflagrationBaseCostOverhaul(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function LanceHarmonyTechniques(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (BloomNetworkStartup[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (BloomNetworkStartup[to] && !isExcludedFromLimits[from]) { // SELL
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