/*
************    *              ************   *********
*               *                        *    *         *
*               *                      *      *          *
*      *****    *                    *        *          *
*          *    *                  *          *          *
*          *    *                *            *         *
************    ************   ************   **********

$GLZD GLAZED DONUTS. ELON'S FAVORITES! BUILDING DECENTRALIZED FRANQUISE FROM SCRATCH 
LFGGGG FAM!
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract GlazedDonut is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _marketingdevelopmentPending;

    address public marketingdevelopmentAddress;
    uint16[3] public marketingdevelopmentFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxTxAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event marketingdevelopmentAddressUpdated(address marketingdevelopmentAddress);
    event marketingdevelopmentFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event marketingdevelopmentFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxTxAmountUpdated(uint256 maxTxAmount);
 
    constructor()
        ERC20(unicode"GlazedDonut", unicode"GLZD") 
    {
        address supplyRecipient = 0xF2BAaC7f3BcA17992155AC5F0d9cEEbc74AB225c;
        
        updateSwapThreshold(50000000 * (10 ** decimals()));

        marketingdevelopmentAddressSetup(0x8Fca1310bDa1B4275f5274E6Ee0e6AFc69487383);
        marketingdevelopmentFeesSetup(100, 300, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(marketingdevelopmentAddress, true);

        updateMaxWalletAmount(3000000000 * (10 ** decimals()));

        updateMaxTxAmount(3000000000 * (10 ** decimals()));

        _mint(supplyRecipient, 100000000000 * (10 ** decimals()));
        _transferOwnership(0xF2BAaC7f3BcA17992155AC5F0d9cEEbc74AB225c);
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

    function marketingdevelopmentAddressSetup(address _newAddress) public onlyOwner {
        marketingdevelopmentAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit marketingdevelopmentAddressUpdated(_newAddress);
    }

    function marketingdevelopmentFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        marketingdevelopmentFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + marketingdevelopmentFees[0];
        totalFees[1] = 0 + marketingdevelopmentFees[1];
        totalFees[2] = 0 + marketingdevelopmentFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit marketingdevelopmentFeesUpdated(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = 0 + _marketingdevelopmentPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _marketingdevelopmentPending > 0) {
                uint256 token2Swap = 0 + _marketingdevelopmentPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 marketingdevelopmentPortion = coinsReceived * _marketingdevelopmentPending / token2Swap;
                if (marketingdevelopmentPortion > 0) {
                    (success,) = payable(address(marketingdevelopmentAddress)).call{value: marketingdevelopmentPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit marketingdevelopmentFeeSent(marketingdevelopmentAddress, marketingdevelopmentPortion);
                }
                _marketingdevelopmentPending = 0;

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
                
                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _marketingdevelopmentPending += fees * marketingdevelopmentFees[txType] / totalFees[txType];

                
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

    function updateMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = _maxTxAmount;
        
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (AMMPairs[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max sell limit");
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