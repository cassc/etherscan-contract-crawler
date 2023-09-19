/*
$SAFEMOG
STACK $MOG REFLECTIONS EVERY 10 MINS 

https://twitter.com/SAFEMOG_erc20

https://t.me/SAFEMOGerc20
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./TokenDividendTracker.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract SAFEMOG is ERC20, ERC20Burnable, Ownable, DividendTrackerFunctions {
    
    uint256 public swapThreshold;
    
    uint256 private _mogketingwalletPending;
    uint256 private _rewardsPending;

    address public mogketingwalletAddress;
    uint16[3] public mogketingwalletFees;

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

    event mogketingwalletAddressUpdated(address mogketingwalletAddress);
    event mogketingwalletFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event mogketingwalletFeeSent(address recipient, uint256 amount);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);
 
    constructor()
        ERC20(unicode"SAFEMOG", unicode"SAFEMOG") 
    {
        address supplyRecipient = 0xe1789Bb2c53502Ba11CD7aBfeE36e1ba62a12641;
        
        updateSwapThreshold(2103450000 * (10 ** decimals()) / 10);

        mogketingwalletAddressSetup(0xff0F73780bfeaf0BF18685bF048a8Fe5828223B9);
        mogketingwalletFeesSetup(200, 200, 0);

        _deployDividendTracker(600, 10 * (10 ** decimals()) / 10, 0xaaeE1A9723aaDB7afA2810263653A34bA2C21C7a);

        gasForProcessingSetup(300000);
        rewardsFeesSetup(200, 200, 0);
        excludeFromDividends(supplyRecipient, true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(mogketingwalletAddress, true);

        updateMaxWalletAmount(206138100000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 4206900000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xe1789Bb2c53502Ba11CD7aBfeE36e1ba62a12641);
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
        return 0 + _mogketingwalletPending + _rewardsPending;
    }

    function mogketingwalletAddressSetup(address _newAddress) public onlyOwner {
        mogketingwalletAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit mogketingwalletAddressUpdated(_newAddress);
    }

    function mogketingwalletFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        mogketingwalletFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + mogketingwalletFees[0] + rewardsFees[0];
        totalFees[1] = 0 + mogketingwalletFees[1] + rewardsFees[1];
        totalFees[2] = 0 + mogketingwalletFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit mogketingwalletFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _swapTokensForOtherRewardTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        path[2] = rewardToken;

        _approve(address(this), address(routerV2), tokenAmount);

        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _sendDividends(uint256 tokenAmount) private {
        _swapTokensForOtherRewardTokens(tokenAmount);

        uint256 dividends = IERC20(rewardToken).balanceOf(address(this));

        if (dividends > 0) {
            bool success = IERC20(rewardToken).approve(address(dividendTracker), dividends);

            if (success) {
                dividendTracker.distributeDividends(dividends);
                emit rewardsFeeSent(dividends);
            }
        }
    }

    function excludeFromDividends(address account, bool isExcluded) public override onlyOwner {
        dividendTracker.excludeFromDividends(account, balanceOf(account), isExcluded);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        rewardsFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + mogketingwalletFees[0] + rewardsFees[0];
        totalFees[1] = 0 + mogketingwalletFees[1] + rewardsFees[1];
        totalFees[2] = 0 + mogketingwalletFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
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
            
            if (false || _mogketingwalletPending > 0) {
                uint256 token2Swap = 0 + _mogketingwalletPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mogketingwalletPortion = coinsReceived * _mogketingwalletPending / token2Swap;
                if (mogketingwalletPortion > 0) {
                    (success,) = payable(address(mogketingwalletAddress)).call{value: mogketingwalletPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit mogketingwalletFeeSent(mogketingwalletAddress, mogketingwalletPortion);
                }
                _mogketingwalletPending = 0;

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
                
                _mogketingwalletPending += fees * mogketingwalletFees[txType] / totalFees[txType];

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
        
        excludeFromDividends(router, true);

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
            excludeFromDividends(pair, true);

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