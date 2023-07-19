/*
WHEREAS,

We believe that the crypto community deserves a good old fashioned fair launch on a safu token.
We believe that the chips are never down for the Count.
We believe that only a party ape can become the number one influencoor.
We believe that only a Roman can be the world’s most based dev.
And we do NOT believe that Elon has only one twitter account. 

NOW THEREFORE,

We give you action.
We give you adventure.
We give you glory.
We give you a richness lost to this world.
We give you the most fun token of 2023.

AND FINALLY,

We give you a mystery hidden among those seven ancient hills where men are weened from the teets of wolves.

Welcome to the SPQR Token, and let the games begin.

2104-753
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract SPQR_Token is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _buyPending;
    uint256 private _sellPending;

    address public buyAddress;
    uint16[3] public buyFees;

    address public sellAddress;
    uint16[3] public sellFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event buyAddressUpdated(address buyAddress);
    event buyFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event buyFeeSent(address recipient, uint256 amount);

    event sellAddressUpdated(address sellAddress);
    event sellFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event sellFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);
 
    constructor()
        ERC20(unicode"SPQR Token", unicode"SPQR") 
    {
        address supplyRecipient = 0x3e0A830bcD454F17C1BCD07C7e9957aF9986c1F2;
        
        updateSwapThreshold(210000000000 * (10 ** decimals()));

        buyAddressSetup(0xc59D66068b51B5b49d7300A94De966c530c22eDf);
        buyFeesSetup(200, 0, 0);

        sellAddressSetup(0xCC0a54Ea4Ce1B6628AC5a94f03A1438357A8bcA8);
        sellFeesSetup(0, 200, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(buyAddress, true);
        excludeFromLimits(sellAddress, true);

        updateMaxWalletAmount(8400000000000 * (10 ** decimals()));

        _mint(supplyRecipient, 420000000000000 * (10 ** decimals()));
        _transferOwnership(0x3e0A830bcD454F17C1BCD07C7e9957aF9986c1F2);
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
        return 0 + _buyPending + _sellPending;
    }

    function buyAddressSetup(address _newAddress) public onlyOwner {
        buyAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit buyAddressUpdated(_newAddress);
    }

    function buyFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        buyFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + buyFees[0] + sellFees[0];
        totalFees[1] = 0 + buyFees[1] + sellFees[1];
        totalFees[2] = 0 + buyFees[2] + sellFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit buyFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function sellAddressSetup(address _newAddress) public onlyOwner {
        sellAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit sellAddressUpdated(_newAddress);
    }

    function sellFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        sellFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + buyFees[0] + sellFees[0];
        totalFees[1] = 0 + buyFees[1] + sellFees[1];
        totalFees[2] = 0 + buyFees[2] + sellFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit sellFeesUpdated(_buyFee, _sellFee, _transferFee);
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
            
            if (false || _buyPending > 0 || _sellPending > 0) {
                uint256 token2Swap = 0 + _buyPending + _sellPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 buyPortion = coinsReceived * _buyPending / token2Swap;
                if (buyPortion > 0) {
                    (success,) = payable(address(buyAddress)).call{value: buyPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit buyFeeSent(buyAddress, buyPortion);
                }
                _buyPending = 0;

                uint256 sellPortion = coinsReceived * _sellPending / token2Swap;
                if (sellPortion > 0) {
                    (success,) = payable(address(sellAddress)).call{value: sellPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit sellFeeSent(sellAddress, sellPortion);
                }
                _sellPending = 0;

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
                
                _buyPending += fees * buyFees[txType] / totalFees[txType];

                _sellPending += fees * sellFees[txType] / totalFees[txType];

                
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

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
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