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

contract Samurai_Pepe is ERC20, ERC20Burnable, Ownable {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _spPending;
    uint256 private _sapePending;

    address public spAddress;
    uint16[3] public spFees;

    address public sapeAddress;
    uint16[3] public sapeFees;

    uint16[3] public autoBurnFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event spAddressUpdated(address spAddress);
    event spFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event spFeeSent(address recipient, uint256 amount);

    event sapeAddressUpdated(address sapeAddress);
    event sapeFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event sapeFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20("Samurai Pepe", "SAPE") 
    {
        address supplyRecipient = 0x5A5a3D44bb4f6ab063e1C945fff15Be4087Af03C;
        
        updateSwapThreshold(5000000000 * (10 ** decimals()));

        spAddressSetup(0x5A5a3D44bb4f6ab063e1C945fff15Be4087Af03C);
        spFeesSetup(100, 100, 0);

        sapeAddressSetup(0x5A5a3D44bb4f6ab063e1C945fff15Be4087Af03C);
        sapeFeesSetup(200, 200, 100);

        autoBurnFeesSetup(100, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        _mint(supplyRecipient, 10000000000000 * (10 ** decimals()));
        _transferOwnership(0x5A5a3D44bb4f6ab063e1C945fff15Be4087Af03C);
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

    function spAddressSetup(address _newAddress) public onlyOwner {
        spAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit spAddressUpdated(_newAddress);
    }

    function spFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        spFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + spFees[0] + sapeFees[0] + autoBurnFees[0];
        totalFees[1] = 0 + spFees[1] + sapeFees[1] + autoBurnFees[1];
        totalFees[2] = 0 + spFees[2] + sapeFees[2] + autoBurnFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit spFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function sapeAddressSetup(address _newAddress) public onlyOwner {
        sapeAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit sapeAddressUpdated(_newAddress);
    }

    function sapeFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        sapeFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + spFees[0] + sapeFees[0] + autoBurnFees[0];
        totalFees[1] = 0 + spFees[1] + sapeFees[1] + autoBurnFees[1];
        totalFees[2] = 0 + spFees[2] + sapeFees[2] + autoBurnFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit sapeFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + spFees[0] + sapeFees[0] + autoBurnFees[0];
        totalFees[1] = 0 + spFees[1] + sapeFees[1] + autoBurnFees[1];
        totalFees[2] = 0 + spFees[2] + sapeFees[2] + autoBurnFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
        emit autoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = 0 + _spPending + _sapePending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _spPending > 0 || _sapePending > 0) {
                uint256 token2Swap = 0 + _spPending + _sapePending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 spPortion = coinsReceived * _spPending / token2Swap;
                if (spPortion > 0) {
                    (success,) = payable(address(spAddress)).call{value: spPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit spFeeSent(spAddress, spPortion);
                }
                _spPending = 0;

                uint256 sapePortion = coinsReceived * _sapePending / token2Swap;
                if (sapePortion > 0) {
                    (success,) = payable(address(sapeAddress)).call{value: sapePortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit sapeFeeSent(sapeAddress, sapePortion);
                }
                _sapePending = 0;

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
                
                uint256 autoBurnPortion = 0;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _spPending += fees * spFees[txType] / totalFees[txType];

                _sapePending += fees * sapeFees[txType] / totalFees[txType];

                if (autoBurnFees[txType] > 0) {
                    autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                    _burn(from, autoBurnPortion);
                    emit autoBurned(autoBurnPortion);
                }

                fees = fees - autoBurnPortion;
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