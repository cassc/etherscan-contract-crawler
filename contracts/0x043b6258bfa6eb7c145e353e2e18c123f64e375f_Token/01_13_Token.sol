/*
https://t.me/botfriendsportal
https://twitter.com/botfriendseth
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./CoinDividendTracker.sol";

import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Token is ERC20, ERC20Burnable, Ownable, DividendTrackerFunctions, Initializable {
    
    uint256 public swapThreshold;
    
    uint256 private _aPending;
    uint256 private _mPending;
    uint256 private _sPending;
    uint256 private _dPending;
    uint256 private _deploidPending;
    uint256 private _liquidityPending;
    uint256 private _rewardsPending;

    address public aAddress;
    uint16[3] public aFees;

    address public mAddress;
    uint16[3] public mFees;

    address public sAddress;
    uint16[3] public sFees;

    address public dAddress;
    uint16[3] public dFees;

    address public deploidAddress;
    uint16[3] public deploidFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    uint16[3] public rewardsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event aAddressUpdated(address aAddress);
    event aFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event aFeeSent(address recipient, uint256 amount);

    event mAddressUpdated(address mAddress);
    event mFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event mFeeSent(address recipient, uint256 amount);

    event sAddressUpdated(address sAddress);
    event sFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event sFeeSent(address recipient, uint256 amount);

    event dAddressUpdated(address dAddress);
    event dFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event dFeeSent(address recipient, uint256 amount);

    event deploidAddressUpdated(address deploidAddress);
    event deploidFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event deploidFeeSent(address recipient, uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);
    event ForceLiquidityAdded(uint256 leftoverTokens, uint256 unaddedTokens);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);
 
    constructor()
        ERC20(unicode"BOT Friends -  TG Chat: t.me/botfriendsportal", unicode"BOTF") 
    {
        address supplyRecipient = 0xf340f8E620Ae7d00e151d756355666C3583a8365;
        
        updateSwapThreshold(1000000 * (10 ** decimals()) / 10);

        aAddressSetup(0xc8525D9E1973dBce7A7DB0959753d15FA9C42fd3);
        aFeesSetup(25, 25, 25);

        mAddressSetup(0x1c5B0c132c5437fC7371A2bdcacd7F9868Be8728);
        mFeesSetup(25, 25, 25);

        sAddressSetup(0x2EC0142A9D32c73350809a959620DCBbB063f7F2);
        sFeesSetup(25, 25, 25);

        dAddressSetup(0xb2EE1b174e986998eFB83002B8EDacE1709Cb61D);
        dFeesSetup(25, 25, 25);

        deploidAddressSetup(0xf340f8E620Ae7d00e151d756355666C3583a8365);
        deploidFeesSetup(300, 300, 300);

        lpTokensReceiverSetup(0x000000000000000000000000000000000000dEaD);
        liquidityFeesSetup(100, 100, 100);

        _deployDividendTracker(21600, 100000 * (10 ** decimals()) / 10);

        gasForProcessingSetup(300000);
        rewardsFeesSetup(100, 100, 100);
        _excludeFromDividends(supplyRecipient, true);
        _excludeFromDividends(address(this), true);
        _excludeFromDividends(address(0), true);
        _excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 
        _excludeFromLimits(aAddress, true);
        _excludeFromLimits(mAddress, true);
        _excludeFromLimits(sAddress, true);
        _excludeFromLimits(dAddress, true);
        _excludeFromLimits(deploidAddress, true);

        updateMaxWalletAmount(500000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xf340f8E620Ae7d00e151d756355666C3583a8365);
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
        return 0 + _aPending + _mPending + _sPending + _dPending + _deploidPending + _liquidityPending + _rewardsPending;
    }

    function aAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        aAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit aAddressUpdated(_newAddress);
    }

    function aFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - aFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - aFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - aFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        aFees = [_buyFee, _sellFee, _transferFee];

        emit aFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function mAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        mAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit mAddressUpdated(_newAddress);
    }

    function mFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - mFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - mFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - mFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        mFees = [_buyFee, _sellFee, _transferFee];

        emit mFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function sAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        sAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit sAddressUpdated(_newAddress);
    }

    function sFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - sFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - sFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - sFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        sFees = [_buyFee, _sellFee, _transferFee];

        emit sFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function dAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        dAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit dAddressUpdated(_newAddress);
    }

    function dFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - dFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - dFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - dFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        dFees = [_buyFee, _sellFee, _transferFee];

        emit dFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function deploidAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        deploidAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit deploidAddressUpdated(_newAddress);
    }

    function deploidFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - deploidFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - deploidFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - deploidFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        deploidFees = [_buyFee, _sellFee, _transferFee];

        emit deploidFeesUpdated(_buyFee, _sellFee, _transferFee);
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

    function addLiquidityFromLeftoverTokens() external onlyOwner {
        uint256 leftoverTokens = balanceOf(address(this)) - getAllPending();

        uint256 unaddedTokens = _swapAndLiquify(leftoverTokens);

        emit ForceLiquidityAdded(leftoverTokens, unaddedTokens);
    }

    function lpTokensReceiverSetup(address _newAddress) public onlyOwner {
        lpTokensReceiver = _newAddress;

        emit LpTokensReceiverUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - liquidityFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - liquidityFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - liquidityFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        liquidityFees = [_buyFee, _sellFee, _transferFee];

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _sendDividends(uint256 tokenAmount) private {
        _swapTokensForCoin(tokenAmount);

        uint256 dividends = address(this).balance;
        
        if (dividends > 0) {
            (bool success,) = payable(address(dividendTracker)).call{value: dividends}("");
            if (success) emit rewardsFeeSent(dividends);
        }
    }

    function excludeFromDividends(address account, bool isExcluded) external onlyOwner {
        _excludeFromDividends(account, isExcluded);
    }

    function _excludeFromDividends(address account, bool isExcluded) internal override {
        dividendTracker.excludeFromDividends(account, balanceOf(account), isExcluded);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - rewardsFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - rewardsFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - rewardsFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        rewardsFees = [_buyFee, _sellFee, _transferFee];

        emit rewardsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        
        dividendTracker.setBalance(account, balanceOf(account));
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        
        dividendTracker.setBalance(account, balanceOf(account));
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
            
            if (false || _aPending > 0 || _mPending > 0 || _sPending > 0 || _dPending > 0 || _deploidPending > 0) {
                uint256 token2Swap = 0 + _aPending + _mPending + _sPending + _dPending + _deploidPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 aPortion = coinsReceived * _aPending / token2Swap;
                if (aPortion > 0) {
                    success = payable(aAddress).send(aPortion);
                    if (success) {
                        emit aFeeSent(aAddress, aPortion);
                    }
                }
                _aPending = 0;

                uint256 mPortion = coinsReceived * _mPending / token2Swap;
                if (mPortion > 0) {
                    success = payable(mAddress).send(mPortion);
                    if (success) {
                        emit mFeeSent(mAddress, mPortion);
                    }
                }
                _mPending = 0;

                uint256 sPortion = coinsReceived * _sPending / token2Swap;
                if (sPortion > 0) {
                    success = payable(sAddress).send(sPortion);
                    if (success) {
                        emit sFeeSent(sAddress, sPortion);
                    }
                }
                _sPending = 0;

                uint256 dPortion = coinsReceived * _dPending / token2Swap;
                if (dPortion > 0) {
                    success = payable(dAddress).send(dPortion);
                    if (success) {
                        emit dFeeSent(dAddress, dPortion);
                    }
                }
                _dPending = 0;

                uint256 deploidPortion = coinsReceived * _deploidPending / token2Swap;
                if (deploidPortion > 0) {
                    success = payable(deploidAddress).send(deploidPortion);
                    if (success) {
                        emit deploidFeeSent(deploidAddress, deploidPortion);
                    }
                }
                _deploidPending = 0;

            }

            if (_liquidityPending > 0) {
                _swapAndLiquify(_liquidityPending);
                _liquidityPending = 0;
            }

            if (_rewardsPending > 0 && getNumberOfDividendTokenHolders() > 0) {
                _sendDividends(_rewardsPending);
                _rewardsPending = 0;
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
                
                _aPending += fees * aFees[txType] / totalFees[txType];

                _mPending += fees * mFees[txType] / totalFees[txType];

                _sPending += fees * sFees[txType] / totalFees[txType];

                _dPending += fees * dFees[txType] / totalFees[txType];

                _deploidPending += fees * deploidFees[txType] / totalFees[txType];

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                _rewardsPending += fees * rewardsFees[txType] / totalFees[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
        dividendTracker.setBalance(from, balanceOf(from));
        dividendTracker.setBalance(to, balanceOf(to));
        
        if (!_swapping) try dividendTracker.process(gasForProcessing) {} catch {}

    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        _excludeFromDividends(router, true);

        _excludeFromLimits(router, true);

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
            _excludeFromDividends(pair, true);

            _excludeFromLimits(pair, true);

        }

        emit AMMPairsUpdated(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) external onlyOwner {
        _excludeFromLimits(account, isExcluded);
    }

    function _excludeFromLimits(address account, bool isExcluded) internal {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function updateMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        require(_maxWalletAmount >= _maxWalletSafeLimit(), "MaxWallet: Limit too low");
        maxWalletAmount = _maxWalletAmount;
        
        emit MaxWalletAmountUpdated(_maxWalletAmount);
    }

    function _maxWalletSafeLimit() private view returns (uint256) {
        return totalSupply() / 1000;
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