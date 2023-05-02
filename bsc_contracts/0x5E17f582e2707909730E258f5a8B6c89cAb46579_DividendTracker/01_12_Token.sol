/*
100% of Supply Locked in LP
BUSD Reflections
95% to holders 5% to Marketing/Development
$DEAL with it.
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./TokenDividendTracker.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract DEAL_with_it is ERC20, ERC20Burnable, Ownable, DividendTrackerFunctions {
    
    IERC20 public feeToken;

    uint256 public swapThreshold;
    
    uint256 private _marketingPending;
    uint256 private _rewardsPending;

    address public marketingAddress;
    uint16[3] public marketingFees;

    uint16[3] public rewardsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event marketingAddressUpdated(address marketingAddress);
    event marketingFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event marketingFeeSent(address recipient, uint256 amount);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20("DEAL with it", "DEAL") 
    {
        address supplyRecipient = 0x1373d764062f279f2E3f3D9d4ED224dA6144089D;
        
        _updateFeeToken(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

        updateSwapThreshold(88809907 * (10 ** decimals()));

        marketingAddressSetup(0x1E5d37A8aE4db20674AA50d511EF8C608b1134a6);
        marketingFeesSetup(5, 20, 0);

        _deployDividendTracker(86400, 1 * (10 ** decimals()), 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

        gasForProcessingSetup(300000);
        rewardsFeesSetup(95, 380, 0);
        excludeFromDividends(supplyRecipient, true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        _mint(supplyRecipient, 177619813501 * (10 ** decimals()));
        _transferOwnership(0x1373d764062f279f2E3f3D9d4ED224dA6144089D);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 5;
    }
    
    function _updateFeeToken(address feeTokenAddress) private {
        feeToken = IERC20(feeTokenAddress);
    }

    function _sendInOtherTokens(address to, uint256 amount) private returns (bool) {
        return feeToken.transfer(to, amount);
    }
    
    function _swapTokensForOtherTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        path[2] = address(feeToken);
        
        _approve(address(this), address(routerV2), tokenAmount);
        
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function marketingAddressSetup(address _newAddress) public onlyOwner {
        marketingAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit marketingAddressUpdated(_newAddress);
    }

    function marketingFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        marketingFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + marketingFees[0] + rewardsFees[0];
        totalFees[1] = 0 + marketingFees[1] + rewardsFees[1];
        totalFees[2] = 0 + marketingFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit marketingFeesUpdated(_buyFee, _sellFee, _transferFee);
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
        
        totalFees[0] = 0 + marketingFees[0] + rewardsFees[0];
        totalFees[1] = 0 + marketingFees[1] + rewardsFees[1];
        totalFees[2] = 0 + marketingFees[2] + rewardsFees[2];
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
        
        bool canSwap = 0 + _marketingPending + _rewardsPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _marketingPending > 0) {
                uint256 token2Swap = 0 + _marketingPending;
                bool success = false;

                _swapTokensForOtherTokens(token2Swap);
                uint256 tokensReceived = feeToken.balanceOf(address(this));
                
                uint256 marketingPortion = tokensReceived * _marketingPending / token2Swap;
                if (marketingPortion > 0) {
                    success = _sendInOtherTokens(marketingAddress, marketingPortion);
                    require(success, "TaxesDefaultRouterWalletOther: Fee transfer error");
                    emit marketingFeeSent(marketingAddress, marketingPortion);
                }
                _marketingPending = 0;

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
                
                _marketingPending += fees * marketingFees[txType] / totalFees[txType];

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