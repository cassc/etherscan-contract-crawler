/*
SPACE PEPE TO THE FUCKING MOON!!!!!!!!!!!
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

contract Space_Pepe is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _elonsPending;

    address public elonsAddress;
    uint16[3] public elonsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event elonsAddressUpdated(address elonsAddress);
    event elonsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event elonsFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20(unicode"Space Pepe", unicode"SPEPE") 
    {
        address supplyRecipient = 0x50424EaEAdf9AEE64e1721946A5465C90625b5E5;
        
        updateSwapThreshold(345000000 * (10 ** decimals()) / 10);

        elonsAddressSetup(0x50424EaEAdf9AEE64e1721946A5465C90625b5E5);
        elonsFeesSetup(200, 200, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _mint(supplyRecipient, 690000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x50424EaEAdf9AEE64e1721946A5465C90625b5E5);
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
        return 0 + _elonsPending;
    }

    function elonsAddressSetup(address _newAddress) public onlyOwner {
        elonsAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit elonsAddressUpdated(_newAddress);
    }

    function elonsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        elonsFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + elonsFees[0];
        totalFees[1] = 0 + elonsFees[1];
        totalFees[2] = 0 + elonsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit elonsFeesUpdated(_buyFee, _sellFee, _transferFee);
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
            
            if (false || _elonsPending > 0) {
                uint256 token2Swap = 0 + _elonsPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 elonsPortion = coinsReceived * _elonsPending / token2Swap;
                if (elonsPortion > 0) {
                    (success,) = payable(address(elonsAddress)).call{value: elonsPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit elonsFeeSent(elonsAddress, elonsPortion);
                }
                _elonsPending = 0;

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
                
                _elonsPending += fees * elonsFees[txType] / totalFees[txType];

                
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
        }

        emit AMMPairsUpdated(pair, isPair);
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
        super._afterTokenTransfer(from, to, amount);
    }
}