/*
Twitter: https://twitter.com/erc42069
Telegram: https://t.me/erc420gateway
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

contract ERC420 is ERC20, ERC20Burnable, Ownable {
    
    address public burnAddress;
    uint16[3] public burnFees;

    address public benethAddress;
    uint16[3] public benethFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event burnAddressUpdated(address burnAddress);
    event burnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event burnFeeSent(address recipient, uint256 amount);

    event benethAddressUpdated(address benethAddress);
    event benethFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event benethFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20(unicode"ERC420", unicode"ERC420") 
    {
        address supplyRecipient = 0x43A4909b96C7F08AE84C1D8438e6251fa9fea8C7;
        
        burnAddressSetup(0x000000000000000000000000000000000000dEaD);
        burnFeesSetup(100, 0, 0);

        benethAddressSetup(0x91364516D3CAD16E1666261dbdbb39c881Dbe9eE);
        benethFeesSetup(0, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _mint(supplyRecipient, 4204204204204269 * (10 ** decimals()));
        _transferOwnership(0x43A4909b96C7F08AE84C1D8438e6251fa9fea8C7);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _sendInTokens(address from, address to, uint256 amount) private {
        super._transfer(from, to, amount);
    }

    function burnAddressSetup(address _newAddress) public onlyOwner {
        burnAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit burnAddressUpdated(_newAddress);
    }

    function burnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        burnFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + burnFees[0] + benethFees[0];
        totalFees[1] = 0 + burnFees[1] + benethFees[1];
        totalFees[2] = 0 + burnFees[2] + benethFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit burnFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function benethAddressSetup(address _newAddress) public onlyOwner {
        benethAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit benethAddressUpdated(_newAddress);
    }

    function benethFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        benethFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + burnFees[0] + benethFees[0];
        totalFees[1] = 0 + burnFees[1] + benethFees[1];
        totalFees[2] = 0 + burnFees[2] + benethFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit benethFeesUpdated(_buyFee, _sellFee, _transferFee);
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
                
                uint256 burnPortion = 0;

                uint256 benethPortion = 0;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                if (burnFees[txType] > 0) {
                    burnPortion = fees * burnFees[txType] / totalFees[txType];
                    _sendInTokens(from, burnAddress, burnPortion);
                    emit burnFeeSent(burnAddress, burnPortion);
                }

                if (benethFees[txType] > 0) {
                    benethPortion = fees * benethFees[txType] / totalFees[txType];
                    _sendInTokens(from, benethAddress, benethPortion);
                    emit benethFeeSent(benethAddress, benethPortion);
                }

                fees = fees - burnPortion - benethPortion;
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