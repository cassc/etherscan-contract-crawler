/*

###########################################
## Token generated with ❤️ on 20lab.app ##
##########################################

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

contract Colpkin is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _colinPending;
    uint256 private _liquidityPending;

    address public colinAddress;
    uint16[3] public colinFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping (address => bool) public AMMPairs;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event colinAddressUpdated(address colinAddress);
    event colinFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event colinFeeSent(address recipient, uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountETH, uint liquidity);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UniswapV2RouterUpdated(address indexed uniswapV2Router);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20("Colpkin", "Colin") 
    {
        address supplyRecipient = 0x9Db7E55879c144d0DdC89F9299C18F45671ab92D;
        
        updateSwapThreshold(50000 * (10 ** decimals()));

        colinAddressSetup(0x2f0d265A0A14dF26D67377F139D65aD347E7e31a);
        colinFeesSetup(0, 800, 0);

        lpTokensReceiverSetup(0x680514ff01330D9e5C1d345F542675ce4bE23086);
        liquidityFeesSetup(0, 400, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()));
        _transferOwnership(0x9Db7E55879c144d0DdC89F9299C18F45671ab92D);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
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

    function colinAddressSetup(address _newAddress) public onlyOwner {
        colinAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit colinAddressUpdated(_newAddress);
    }

    function colinFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        colinFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + colinFees[0] + liquidityFees[0];
        totalFees[1] = 0 + colinFees[1] + liquidityFees[1];
        totalFees[2] = 0 + colinFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit colinFeesUpdated(_buyFee, _sellFee, _transferFee);
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

        totalFees[0] = 0 + colinFees[0] + liquidityFees[0];
        totalFees[1] = 0 + colinFees[1] + liquidityFees[1];
        totalFees[2] = 0 + colinFees[2] + liquidityFees[2];
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
        
        bool canSwap = 0 + _colinPending + _liquidityPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _colinPending > 0) {
                uint256 token2Swap = 0 + _colinPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 colinPortion = coinsReceived * _colinPending / token2Swap;
                (success,) = payable(address(colinAddress)).call{value: colinPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit colinFeeSent(colinAddress, colinPortion);
                _colinPending = 0;

            }

            if (_liquidityPending > 0) {
                _liquidityPending = _swapAndLiquify(_liquidityPending);
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
                
                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _colinPending += fees * colinFees[txType] / totalFees[txType];

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateUniswapV2Router(address router) private {
        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
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