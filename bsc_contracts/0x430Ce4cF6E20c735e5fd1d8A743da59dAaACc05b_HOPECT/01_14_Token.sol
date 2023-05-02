/*
############################ WELCOME ############################
THANK YOU FOR THE TRUST AND LET'S MAKE SOMETHING GREAT TOGETHER
############################ 318798 ############################
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./Pausable.sol";
import "./TokenRecover.sol";
import "./CoinDividendTracker.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract HOPECT is ERC20, ERC20Burnable, Ownable, Pausable, TokenRecover, DividendTrackerFunctions {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _hopectprojectsPending;
    uint256 private _devteamPending;
    uint256 private _liquidityPending;
    uint256 private _rewardsPending;

    address public hopectprojectsAddress;
    uint16[3] public hopectprojectsFees;

    address public devteamAddress;
    uint16[3] public devteamFees;

    uint16[3] public autoBurnFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    uint16[3] public rewardsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event hopectprojectsAddressUpdated(address hopectprojectsAddress);
    event hopectprojectsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event hopectprojectsFeeSent(address recipient, uint256 amount);

    event devteamAddressUpdated(address devteamAddress);
    event devteamFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event devteamFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20("HOPECT", "HOPECT") 
    {
        address supplyRecipient = 0xf322E097CD2ebf5863Ee66877053f25792AA4E26;
        
        updateSwapThreshold(4444445 * (10 ** decimals()));

        hopectprojectsAddressSetup(0xBC114cf4160b6C995F6033536C6E80ed724D2b45);
        hopectprojectsFeesSetup(300, 1100, 0);

        devteamAddressSetup(0xEF9c0780137Fa3359C257D15232aD48f4ea23769);
        devteamFeesSetup(100, 100, 0);

        autoBurnFeesSetup(50, 100, 0);

        lpTokensReceiverSetup(0xf322E097CD2ebf5863Ee66877053f25792AA4E26);
        liquidityFeesSetup(300, 1100, 0);

        _deployDividendTracker(604800, 1000000 * (10 ** decimals()));

        gasForProcessingSetup(300000);
        rewardsFeesSetup(100, 100, 0);
        excludeFromDividends(supplyRecipient, true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        _mint(supplyRecipient, 8888888888 * (10 ** decimals()));
        _transferOwnership(0xf322E097CD2ebf5863Ee66877053f25792AA4E26);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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

    function hopectprojectsAddressSetup(address _newAddress) public onlyOwner {
        hopectprojectsAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit hopectprojectsAddressUpdated(_newAddress);
    }

    function hopectprojectsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        hopectprojectsFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + hopectprojectsFees[0] + devteamFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + hopectprojectsFees[1] + devteamFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + hopectprojectsFees[2] + devteamFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit hopectprojectsFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function devteamAddressSetup(address _newAddress) public onlyOwner {
        devteamAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit devteamAddressUpdated(_newAddress);
    }

    function devteamFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        devteamFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + hopectprojectsFees[0] + devteamFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + hopectprojectsFees[1] + devteamFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + hopectprojectsFees[2] + devteamFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit devteamFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + hopectprojectsFees[0] + devteamFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + hopectprojectsFees[1] + devteamFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + hopectprojectsFees[2] + devteamFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
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

        totalFees[0] = 0 + hopectprojectsFees[0] + devteamFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + hopectprojectsFees[1] + devteamFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + hopectprojectsFees[2] + devteamFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _sendDividends(uint256 tokenAmount) private {
        _swapTokensForCoin(tokenAmount);

        uint256 dividends = address(this).balance;
        
        if (dividends > 0) {
            (bool success,) = payable(address(dividendTracker)).call{value: dividends}("");
            if(success) emit rewardsFeeSent(dividends);
        }
    }

    function excludeFromDividends(address account, bool isExcluded) public override onlyOwner {
        dividendTracker.excludeFromDividends(account, balanceOf(account), isExcluded);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        rewardsFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + hopectprojectsFees[0] + devteamFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + hopectprojectsFees[1] + devteamFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + hopectprojectsFees[2] + devteamFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
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
        
        bool canSwap = 0 + _hopectprojectsPending + _devteamPending + _liquidityPending + _rewardsPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _hopectprojectsPending > 0 || _devteamPending > 0) {
                uint256 token2Swap = 0 + _hopectprojectsPending + _devteamPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 hopectprojectsPortion = coinsReceived * _hopectprojectsPending / token2Swap;
                if (hopectprojectsPortion > 0) {
                    (success,) = payable(address(hopectprojectsAddress)).call{value: hopectprojectsPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit hopectprojectsFeeSent(hopectprojectsAddress, hopectprojectsPortion);
                }
                _hopectprojectsPending = 0;

                uint256 devteamPortion = coinsReceived * _devteamPending / token2Swap;
                if (devteamPortion > 0) {
                    (success,) = payable(address(devteamAddress)).call{value: devteamPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit devteamFeeSent(devteamAddress, devteamPortion);
                }
                _devteamPending = 0;

            }

            if (_liquidityPending > 10) {
                _liquidityPending = _swapAndLiquify(_liquidityPending);
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
                
                uint256 autoBurnPortion = 0;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _hopectprojectsPending += fees * hopectprojectsFees[txType] / totalFees[txType];

                _devteamPending += fees * devteamFees[txType] / totalFees[txType];

                if (autoBurnFees[txType] > 0) {
                    autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                    _burn(from, autoBurnPortion);
                    emit autoBurned(autoBurnPortion);
                }

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                _rewardsPending += fees * rewardsFees[txType] / totalFees[txType];

                fees = fees - autoBurnPortion;
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
        whenNotPaused
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