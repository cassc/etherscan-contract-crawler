/*
THE KING DADDY + PAPPA PEPE = THE MAGIC STARTS HERE

$ Play 2 Earn
$ Pepe Exchange
$ Pepe Games Arcade
$ Pepe Exchange
$ Pepe Charity 

$ Website: https://pappapepe.com
$ Telegram: https://t.me/pappapepe
$ Twitter: https://twitter.com/PappaPepeToken
$ Facebook: https://www.facebook.com/thepappapepe
$ P2E Games Arcade: https://arcade.pappapepe.com
$ Pepe Merch: Website: https://shop.pappapepe.com 
$ P2E Games Arcade: https://arcade.pappapepe.com
$ Pappa Pepe NFT's: https://nft.pappapepe.com
$ Pappa Pepe Charity: https://charity.pappapepe.com

⣿⣿⣿⣿⣿⣿⣿⠛⢩⣴⣶⣶⣶⣌⠙⠫⠛⢋⣭⣤⣤⣤
⣿⣿⣿⣿⣿⡟⢡⣾⣿⠿⣛⣛⣛⣛⣛⡳⠆⢻⣿⣿⣿⠿⠿⠷⡌
⣿⣿⣿⣿⠏⣰⣿⣿⣴⣿⣿⣿⡿⠟⠛⠛⠒⠄⢶⣶⣶⣾⡿⠶⠒⠲⠌
⣿⣿⠏⣡⢨⣝⡻⠿⣿⢛⣩⡵⠞⡫⠭⠭⣭⠭⠤⠈⠭⠒⣒⠩⠭⠭⣍⠒⠈
⡿⢁⣾⣿⣸⣿⣿⣷⣬⡉⠁⠄⠁⠄⠄⠄⠄⠄⠄⠄⣶⠄⠄⠄⠄⠄⠄⠄⠄⢀
⢡⣾⣿⣿⣿⣿⣿⣿⣿⣧⡀⠄⠄⠄⠄⠄⠄⠄⢀⣠⣿⣦⣤⣀⣀⣀⣀⠄
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⡶⢇⣰⣿⣿⣟⠿⠿⠿⠿⠟
⣿⣿⣿⣿⣿⣿⣿⡟⢛⡛⠿⠿⣿⣧⣶⣶⣿⣿⣿⣿⣿⣷⣼⣿⣿⣿⣧
⠘⢿⣿⣿⣿⣿⣿⡇⢿⡿⠿⠦⣤⣈⣙⡛⠿⠿⠿⣿⣿⣿⣿⠿⠿⠟⠛⡀
⠄⠄⠉⠻⢿⣿⣿⣷⣬⣙⠳⠶⢶⣤⣍⣙⡛⠓⠒⠶⠶⠶⠶⠖⢒⣛⣛⠁
⠄⠄⠄⠄⠄⠈⠛⠛⠿⠿⣿⣷⣤⣤⣈⣉⣛⣛⣛⡛⠛⠛⠿⠿⠿⠟⢋
⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠉⠉⣻⣿⣿⣿⣿⡿⠿⠛⠃⠄⠙


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

contract Token is ERC20, ERC20Burnable, Ownable {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _taxsethpappaPending;
    uint256 private _taxesethpappaPending;

    address public taxsethpappaAddress;
    uint16[3] public taxsethpappaFees;

    address public taxesethpappaAddress;
    uint16[3] public taxesethpappaFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event taxsethpappaAddressUpdated(address taxsethpappaAddress);
    event taxsethpappaFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event taxsethpappaFeeSent(address recipient, uint256 amount);

    event taxesethpappaAddressUpdated(address taxesethpappaAddress);
    event taxesethpappaFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event taxesethpappaFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20(unicode"PAPPAPEPE.COM", unicode"PAPPAPEPE") 
    {
        address supplyRecipient = 0xADd016aA8A0fdB6AAC6c9f59008AE67A11B82a53;
        
        updateSwapThreshold(388889 * (10 ** decimals()));

        taxsethpappaAddressSetup(0x283734b4973069aaEB9893843eae4c3584f1FB7c);
        taxsethpappaFeesSetup(0, 0, 0);

        taxesethpappaAddressSetup(0x283734b4973069aaEB9893843eae4c3584f1FB7c);
        taxesethpappaFeesSetup(0, 400, 400);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _mint(supplyRecipient, 777777777 * (10 ** decimals()));
        _transferOwnership(0xADd016aA8A0fdB6AAC6c9f59008AE67A11B82a53);
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

    function taxsethpappaAddressSetup(address _newAddress) public onlyOwner {
        taxsethpappaAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit taxsethpappaAddressUpdated(_newAddress);
    }

    function taxsethpappaFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        taxsethpappaFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + taxsethpappaFees[0] + taxesethpappaFees[0];
        totalFees[1] = 0 + taxsethpappaFees[1] + taxesethpappaFees[1];
        totalFees[2] = 0 + taxsethpappaFees[2] + taxesethpappaFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit taxsethpappaFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function taxesethpappaAddressSetup(address _newAddress) public onlyOwner {
        taxesethpappaAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit taxesethpappaAddressUpdated(_newAddress);
    }

    function taxesethpappaFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        taxesethpappaFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + taxsethpappaFees[0] + taxesethpappaFees[0];
        totalFees[1] = 0 + taxsethpappaFees[1] + taxesethpappaFees[1];
        totalFees[2] = 0 + taxsethpappaFees[2] + taxesethpappaFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit taxesethpappaFeesUpdated(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = 0 + _taxsethpappaPending + _taxesethpappaPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _taxsethpappaPending > 0 || _taxesethpappaPending > 0) {
                uint256 token2Swap = 0 + _taxsethpappaPending + _taxesethpappaPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 taxsethpappaPortion = coinsReceived * _taxsethpappaPending / token2Swap;
                if (taxsethpappaPortion > 0) {
                    (success,) = payable(address(taxsethpappaAddress)).call{value: taxsethpappaPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit taxsethpappaFeeSent(taxsethpappaAddress, taxsethpappaPortion);
                }
                _taxsethpappaPending = 0;

                uint256 taxesethpappaPortion = coinsReceived * _taxesethpappaPending / token2Swap;
                if (taxesethpappaPortion > 0) {
                    (success,) = payable(address(taxesethpappaAddress)).call{value: taxesethpappaPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit taxesethpappaFeeSent(taxesethpappaAddress, taxesethpappaPortion);
                }
                _taxesethpappaPending = 0;

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
                
                _taxsethpappaPending += fees * taxsethpappaFees[txType] / totalFees[txType];

                _taxesethpappaPending += fees * taxesethpappaFees[txType] / totalFees[txType];

                
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