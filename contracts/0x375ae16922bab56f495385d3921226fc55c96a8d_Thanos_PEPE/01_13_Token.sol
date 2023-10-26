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
import "./TokenRecover.sol";
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Thanos_PEPE is ERC20, ERC20Burnable, Ownable, TokenRecover, Initializable {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _infinityPending;
    uint256 private _operationsPending;
    uint256 private _liquidityPending;

    address public infinityAddress;
    uint16[3] public infinityFees;

    address public operationsAddress;
    uint16[3] public operationsFees;

    address public liquidityAddress;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event infinityAddressUpdated(address infinityAddress);
    event infinityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event infinityFeeSent(address recipient, uint256 amount);

    event operationsAddressUpdated(address operationsAddress);
    event operationsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event operationsFeeSent(address recipient, uint256 amount);

    event liquidityAddressUpdated(address liquidityAddress);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20(unicode"Thanos PEPE", unicode"SNAP") 
    {
        address supplyRecipient = 0x029eaeE50AF0E25E0112124845f23F1a7d461042;
        
        updateSwapThreshold(2100000 * (10 ** decimals()) / 10);

        infinityAddressSetup(0x5FA76b9E898254d4519a70FDa759c9d11D7a51ca);
        infinityFeesSetup(70, 30, 0);

        operationsAddressSetup(0x96926ae8715De8141Fec0813F1CD8a48c2f319F5);
        operationsFeesSetup(100, 100, 0);

        liquidityAddressSetup(0xb904Db0bf2A0b69B7683DaCB33A6945C7D939651);
        liquidityFeesSetup(30, 70, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _mint(supplyRecipient, 4200000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x029eaeE50AF0E25E0112124845f23F1a7d461042);
    }
    
    function initialize(address _router) initializer external {
        _updateRouterV2(_router);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function blacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;

        emit BlacklistUpdated(account, isBlacklisted);
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
        return 0 + _infinityPending + _operationsPending + _liquidityPending;
    }

    function infinityAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        infinityAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit infinityAddressUpdated(_newAddress);
    }

    function infinityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - infinityFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - infinityFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - infinityFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        infinityFees = [_buyFee, _sellFee, _transferFee];

        emit infinityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function operationsAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        operationsAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit operationsAddressUpdated(_newAddress);
    }

    function operationsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - operationsFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - operationsFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - operationsFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        operationsFees = [_buyFee, _sellFee, _transferFee];

        emit operationsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function liquidityAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        liquidityAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit liquidityAddressUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - liquidityFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - liquidityFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - liquidityFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        liquidityFees = [_buyFee, _sellFee, _transferFee];

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
            
            if (false || _infinityPending > 0 || _operationsPending > 0 || _liquidityPending > 0) {
                uint256 token2Swap = 0 + _infinityPending + _operationsPending + _liquidityPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 infinityPortion = coinsReceived * _infinityPending / token2Swap;
                if (infinityPortion > 0) {
                    success = payable(infinityAddress).send(infinityPortion);
                    if (success) {
                        emit infinityFeeSent(infinityAddress, infinityPortion);
                    }
                }
                _infinityPending = 0;

                uint256 operationsPortion = coinsReceived * _operationsPending / token2Swap;
                if (operationsPortion > 0) {
                    success = payable(operationsAddress).send(operationsPortion);
                    if (success) {
                        emit operationsFeeSent(operationsAddress, operationsPortion);
                    }
                }
                _operationsPending = 0;

                uint256 liquidityPortion = coinsReceived * _liquidityPending / token2Swap;
                if (liquidityPortion > 0) {
                    success = payable(liquidityAddress).send(liquidityPortion);
                    if (success) {
                        emit liquidityFeeSent(liquidityAddress, liquidityPortion);
                    }
                }
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
                
                _infinityPending += fees * infinityFees[txType] / totalFees[txType];

                _operationsPending += fees * operationsFees[txType] / totalFees[txType];

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
        require(!blacklisted[from] && !blacklisted[to], "Blacklist: Sender or recipient is blacklisted");

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}