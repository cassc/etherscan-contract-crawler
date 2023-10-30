/*

#####################################
Token generated with ❤️ on 20lab.app
#####################################

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

contract DontThreadOnMe is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mileiPending;
    uint256 private _developersPending;
    uint256 private _liquidityPending;

    address public mileiAddress;
    uint16[3] public mileiFees;

    address public developersAddress;
    uint16[3] public developersFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event mileiAddressUpdated(address mileiAddress);
    event mileiFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event mileiFeeSent(address recipient, uint256 amount);

    event developersAddressUpdated(address developersAddress);
    event developersFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event developersFeeSent(address recipient, uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20(unicode"DontThreadOnMe", unicode"MILEI") 
    {
        address supplyRecipient = 0x888DC7E8745de40Ee80414B1796A1d481774dC31;
        
        updateSwapThreshold(440000 * (10 ** decimals()) / 10);

        mileiAddressSetup(0xF96a94bf79Dea094e8D78Cb8a161d87f79E76d3C);
        mileiFeesSetup(100, 100, 0);

        developersAddressSetup(0x8205B55667585af89A78b7cADB1C0509359D438f);
        developersFeesSetup(100, 100, 0);

        lpTokensReceiverSetup(0x888DC7E8745de40Ee80414B1796A1d481774dC31);
        liquidityFeesSetup(100, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _mint(supplyRecipient, 460447030 * (10 ** decimals()) / 10);
        _transferOwnership(0x888DC7E8745de40Ee80414B1796A1d481774dC31);
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
        return 0 + _mileiPending + _developersPending + _liquidityPending;
    }

    function mileiAddressSetup(address _newAddress) public onlyOwner {
        mileiAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit mileiAddressUpdated(_newAddress);
    }

    function mileiFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        mileiFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + mileiFees[0] + developersFees[0] + liquidityFees[0];
        totalFees[1] = 0 + mileiFees[1] + developersFees[1] + liquidityFees[1];
        totalFees[2] = 0 + mileiFees[2] + developersFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit mileiFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function developersAddressSetup(address _newAddress) public onlyOwner {
        developersAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit developersAddressUpdated(_newAddress);
    }

    function developersFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        developersFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + mileiFees[0] + developersFees[0] + liquidityFees[0];
        totalFees[1] = 0 + mileiFees[1] + developersFees[1] + liquidityFees[1];
        totalFees[2] = 0 + mileiFees[2] + developersFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit developersFeesUpdated(_buyFee, _sellFee, _transferFee);
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

        totalFees[0] = 0 + mileiFees[0] + developersFees[0] + liquidityFees[0];
        totalFees[1] = 0 + mileiFees[1] + developersFees[1] + liquidityFees[1];
        totalFees[2] = 0 + mileiFees[2] + developersFees[2] + liquidityFees[2];
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
            
            if (false || _mileiPending > 0 || _developersPending > 0) {
                uint256 token2Swap = 0 + _mileiPending + _developersPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mileiPortion = coinsReceived * _mileiPending / token2Swap;
                if (mileiPortion > 0) {
                    (success,) = payable(address(mileiAddress)).call{value: mileiPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit mileiFeeSent(mileiAddress, mileiPortion);
                }
                _mileiPending = 0;

                uint256 developersPortion = coinsReceived * _developersPending / token2Swap;
                if (developersPortion > 0) {
                    (success,) = payable(address(developersAddress)).call{value: developersPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit developersFeeSent(developersAddress, developersPortion);
                }
                _developersPending = 0;

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
                
                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _mileiPending += fees * mileiFees[txType] / totalFees[txType];

                _developersPending += fees * developersFees[txType] / totalFees[txType];

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                
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