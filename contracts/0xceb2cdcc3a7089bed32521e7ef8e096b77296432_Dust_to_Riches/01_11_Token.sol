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

contract Dust_to_Riches is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _gamesprizesanddevelopmentPending;
    uint256 private _schillcreateandearnPending;
    uint256 private _communitymodsPending;
    uint256 private _communitytreasurydaoPending;
    uint256 private _operatingcostsPending;
    uint256 private _liquidityPending;

    address public gamesprizesanddevelopmentAddress;
    uint16[3] public gamesprizesanddevelopmentFees;

    address public schillcreateandearnAddress;
    uint16[3] public schillcreateandearnFees;

    address public communitymodsAddress;
    uint16[3] public communitymodsFees;

    address public communitytreasurydaoAddress;
    uint16[3] public communitytreasurydaoFees;

    address public operatingcostsAddress;
    uint16[3] public operatingcostsFees;

    uint16[3] public autoBurnFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxTxAmount;

    mapping (address => uint256) public lastTrade;
    uint256 public tradeCooldownTime;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event gamesprizesanddevelopmentAddressUpdated(address gamesprizesanddevelopmentAddress);
    event gamesprizesanddevelopmentFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event gamesprizesanddevelopmentFeeSent(address recipient, uint256 amount);

    event schillcreateandearnAddressUpdated(address schillcreateandearnAddress);
    event schillcreateandearnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event schillcreateandearnFeeSent(address recipient, uint256 amount);

    event communitymodsAddressUpdated(address communitymodsAddress);
    event communitymodsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event communitymodsFeeSent(address recipient, uint256 amount);

    event communitytreasurydaoAddressUpdated(address communitytreasurydaoAddress);
    event communitytreasurydaoFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event communitytreasurydaoFeeSent(address recipient, uint256 amount);

    event operatingcostsAddressUpdated(address operatingcostsAddress);
    event operatingcostsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event operatingcostsFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxTxAmountUpdated(uint256 maxTxAmount);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);
 
    constructor()
        ERC20(unicode"Dust to Riches", unicode"D2R") 
    {
        address supplyRecipient = 0xA2a1BD3FAa19d08e26aa6629B1E5F82772B7E811;
        
        updateSwapThreshold(25000 * (10 ** decimals()));

        gamesprizesanddevelopmentAddressSetup(0x7C485edb71e52Fd43c4613E8c27De543A223aB38);
        gamesprizesanddevelopmentFeesSetup(175, 175, 0);

        schillcreateandearnAddressSetup(0xc768F178cA451A25104dAAa729D40d9D3c700A29);
        schillcreateandearnFeesSetup(100, 0, 0);

        communitymodsAddressSetup(0x41c27C64F30E68D8c25f8722D67c321df4916537);
        communitymodsFeesSetup(25, 25, 0);

        communitytreasurydaoAddressSetup(0x4AccDed53EE120CaA75ced42213C28e59F9DD536);
        communitytreasurydaoFeesSetup(50, 50, 0);

        operatingcostsAddressSetup(0xF13A0143a63346B19eE59B426f4457D457A27Bc8);
        operatingcostsFeesSetup(50, 50, 0);

        autoBurnFeesSetup(0, 100, 0);

        lpTokensReceiverSetup(0x0000000000000000000000000000000000000000);
        liquidityFeesSetup(100, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(gamesprizesanddevelopmentAddress, true);
        excludeFromLimits(schillcreateandearnAddress, true);
        excludeFromLimits(communitymodsAddress, true);
        excludeFromLimits(communitytreasurydaoAddress, true);
        excludeFromLimits(operatingcostsAddress, true);

        updateMaxWalletAmount(250000 * (10 ** decimals()));

        updateMaxTxAmount(125000 * (10 ** decimals()));

        updateTradeCooldownTime(600);

        _mint(supplyRecipient, 50000000 * (10 ** decimals()));
        _transferOwnership(0xA2a1BD3FAa19d08e26aa6629B1E5F82772B7E811);
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

    function gamesprizesanddevelopmentAddressSetup(address _newAddress) public onlyOwner {
        gamesprizesanddevelopmentAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit gamesprizesanddevelopmentAddressUpdated(_newAddress);
    }

    function gamesprizesanddevelopmentFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        gamesprizesanddevelopmentFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit gamesprizesanddevelopmentFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function schillcreateandearnAddressSetup(address _newAddress) public onlyOwner {
        schillcreateandearnAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit schillcreateandearnAddressUpdated(_newAddress);
    }

    function schillcreateandearnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        schillcreateandearnFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit schillcreateandearnFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function communitymodsAddressSetup(address _newAddress) public onlyOwner {
        communitymodsAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit communitymodsAddressUpdated(_newAddress);
    }

    function communitymodsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        communitymodsFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit communitymodsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function communitytreasurydaoAddressSetup(address _newAddress) public onlyOwner {
        communitytreasurydaoAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit communitytreasurydaoAddressUpdated(_newAddress);
    }

    function communitytreasurydaoFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        communitytreasurydaoFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit communitytreasurydaoFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function operatingcostsAddressSetup(address _newAddress) public onlyOwner {
        operatingcostsAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit operatingcostsAddressUpdated(_newAddress);
    }

    function operatingcostsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        operatingcostsFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit operatingcostsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
        emit autoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
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

        totalFees[0] = 0 + gamesprizesanddevelopmentFees[0] + schillcreateandearnFees[0] + communitymodsFees[0] + communitytreasurydaoFees[0] + operatingcostsFees[0] + autoBurnFees[0] + liquidityFees[0];
        totalFees[1] = 0 + gamesprizesanddevelopmentFees[1] + schillcreateandearnFees[1] + communitymodsFees[1] + communitytreasurydaoFees[1] + operatingcostsFees[1] + autoBurnFees[1] + liquidityFees[1];
        totalFees[2] = 0 + gamesprizesanddevelopmentFees[2] + schillcreateandearnFees[2] + communitymodsFees[2] + communitytreasurydaoFees[2] + operatingcostsFees[2] + autoBurnFees[2] + liquidityFees[2];
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
        
        bool canSwap = 0 + _gamesprizesanddevelopmentPending + _schillcreateandearnPending + _communitymodsPending + _communitytreasurydaoPending + _operatingcostsPending + _liquidityPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _gamesprizesanddevelopmentPending > 0 || _schillcreateandearnPending > 0 || _communitymodsPending > 0 || _communitytreasurydaoPending > 0 || _operatingcostsPending > 0) {
                uint256 token2Swap = 0 + _gamesprizesanddevelopmentPending + _schillcreateandearnPending + _communitymodsPending + _communitytreasurydaoPending + _operatingcostsPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 gamesprizesanddevelopmentPortion = coinsReceived * _gamesprizesanddevelopmentPending / token2Swap;
                if (gamesprizesanddevelopmentPortion > 0) {
                    (success,) = payable(address(gamesprizesanddevelopmentAddress)).call{value: gamesprizesanddevelopmentPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit gamesprizesanddevelopmentFeeSent(gamesprizesanddevelopmentAddress, gamesprizesanddevelopmentPortion);
                }
                _gamesprizesanddevelopmentPending = 0;

                uint256 schillcreateandearnPortion = coinsReceived * _schillcreateandearnPending / token2Swap;
                if (schillcreateandearnPortion > 0) {
                    (success,) = payable(address(schillcreateandearnAddress)).call{value: schillcreateandearnPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit schillcreateandearnFeeSent(schillcreateandearnAddress, schillcreateandearnPortion);
                }
                _schillcreateandearnPending = 0;

                uint256 communitymodsPortion = coinsReceived * _communitymodsPending / token2Swap;
                if (communitymodsPortion > 0) {
                    (success,) = payable(address(communitymodsAddress)).call{value: communitymodsPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit communitymodsFeeSent(communitymodsAddress, communitymodsPortion);
                }
                _communitymodsPending = 0;

                uint256 communitytreasurydaoPortion = coinsReceived * _communitytreasurydaoPending / token2Swap;
                if (communitytreasurydaoPortion > 0) {
                    (success,) = payable(address(communitytreasurydaoAddress)).call{value: communitytreasurydaoPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit communitytreasurydaoFeeSent(communitytreasurydaoAddress, communitytreasurydaoPortion);
                }
                _communitytreasurydaoPending = 0;

                uint256 operatingcostsPortion = coinsReceived * _operatingcostsPending / token2Swap;
                if (operatingcostsPortion > 0) {
                    (success,) = payable(address(operatingcostsAddress)).call{value: operatingcostsPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit operatingcostsFeeSent(operatingcostsAddress, operatingcostsPortion);
                }
                _operatingcostsPending = 0;

            }

            if (_liquidityPending > 10) {
                _liquidityPending = _swapAndLiquify(_liquidityPending);
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
                
                _gamesprizesanddevelopmentPending += fees * gamesprizesanddevelopmentFees[txType] / totalFees[txType];

                _schillcreateandearnPending += fees * schillcreateandearnFees[txType] / totalFees[txType];

                _communitymodsPending += fees * communitymodsFees[txType] / totalFees[txType];

                _communitytreasurydaoPending += fees * communitytreasurydaoFees[txType] / totalFees[txType];

                _operatingcostsPending += fees * operatingcostsFees[txType] / totalFees[txType];

                if (autoBurnFees[txType] > 0) {
                    autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                    _burn(from, autoBurnPortion);
                    emit autoBurned(autoBurnPortion);
                }

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

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

    function updateTradeCooldownTime(uint256 _tradeCooldownTime) public onlyOwner {
        require(_tradeCooldownTime <= 7 days, "Antibot: Trade cooldown too long.");
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        if(!isExcludedFromLimits[from])
            require(lastTrade[from] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction sender is in anti-bot cooldown");
        if(!isExcludedFromLimits[to])
            require(lastTrade[to] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction recipient is in anti-bot cooldown");

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (!isExcludedFromLimits[to]) {
            require(balanceOf(to) <= maxWalletAmount, "MaxWallet: Cannot exceed max wallet limit");
        }

        if (AMMPairs[from] && !isExcludedFromLimits[to]) lastTrade[to] = block.timestamp;
        else if (AMMPairs[to] && !isExcludedFromLimits[from]) lastTrade[from] = block.timestamp;

        super._afterTokenTransfer(from, to, amount);
    }
}