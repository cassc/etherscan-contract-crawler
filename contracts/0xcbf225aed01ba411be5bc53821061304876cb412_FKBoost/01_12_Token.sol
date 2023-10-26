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
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract FKBoost is ERC20, ERC20Burnable, Ownable, Initializable {
    
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
 
    constructor()
        ERC20(unicode"FKBoost", unicode"FBoost") 
    {
        address supplyRecipient = 0xF8d826e3200da6E73658f803e054318a7225FE22;
        
        updateSwapThreshold(0 * (10 ** decimals()) / 10);

        buyAddressSetup(0x658de062e5491ac8773D04550CE7E8F45985Cb9e);
        buyFeesSetup(100, 0, 0);

        sellAddressSetup(0x658de062e5491ac8773D04550CE7E8F45985Cb9e);
        sellFeesSetup(0, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _mint(supplyRecipient, 10000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xF8d826e3200da6E73658f803e054318a7225FE22);
    }
    
    function initialize(address _router) initializer external {
        _updateRouterV2(_router);
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
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        buyAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit buyAddressUpdated(_newAddress);
    }

    function buyFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - buyFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - buyFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - buyFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        buyFees = [_buyFee, _sellFee, _transferFee];

        emit buyFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function sellAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        sellAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit sellAddressUpdated(_newAddress);
    }

    function sellFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - sellFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - sellFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - sellFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        sellFees = [_buyFee, _sellFee, _transferFee];

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
                    success = payable(buyAddress).send(buyPortion);
                    if (success) {
                        emit buyFeeSent(buyAddress, buyPortion);
                    }
                }
                _buyPending = 0;

                uint256 sellPortion = coinsReceived * _sellPending / token2Swap;
                if (sellPortion > 0) {
                    success = payable(sellAddress).send(sellPortion);
                    if (success) {
                        emit sellFeeSent(sellAddress, sellPortion);
                    }
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
        
        _setAMMPair(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) external onlyOwner {
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