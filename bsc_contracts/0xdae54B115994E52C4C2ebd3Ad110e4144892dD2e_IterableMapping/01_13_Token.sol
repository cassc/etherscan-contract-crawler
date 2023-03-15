/*
*Flork: Submitted for verification at BscScan.com/ on 2023-03-15 #FLK
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./TokenRecover.sol";
import "./TokenDividendTracker.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract FlorK is ERC20, ERC20Burnable, Ownable, TokenRecover, DividendTrackerFunctions {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _fundPending;
    uint256 private _investedPending;
    uint256 private _liquidityPending;
    uint256 private _rewardsPending;

    address public fundAddress;
    uint16[3] public fundFees;

    address public investedAddress;
    uint16[3] public investedFees;

    uint16[3] public autoBurnFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    uint16[3] public rewardsFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    mapping (address => uint256) public lastTrade;
    uint256 public tradeCooldownTime;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event fundAddressUpdated(address fundAddress);
    event fundFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event fundFeeSent(address recipient, uint256 amount);

    event investedAddressUpdated(address investedAddress);
    event investedFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event investedFeeSent(address recipient, uint256 amount);

    event autoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event autoBurned(uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountETH, uint liquidity);

    event rewardsFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event rewardsFeeSent(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UniswapV2RouterUpdated(address indexed uniswapV2Router);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);
 
    constructor()
        ERC20("FlorK", "FLK") 
    {
        address supplyRecipient = 0x3E02ec7678BD891A30adBC234245D9DFE6Fe37E4;
        
        updateSwapThreshold(500000 * (10 ** decimals()));

        fundAddressSetup(0x47767301E91Fe247ffd0f37a9885262Fd77d31bE);
        fundFeesSetup(390, 390, 10);

        investedAddressSetup(0xeE8a4a1c9BB964ac47dB9d2A5Dd57653A96275e1);
        investedFeesSetup(10, 10, 10);

        autoBurnFeesSetup(100, 100, 10);

        lpTokensReceiverSetup(0x0000000000000000000000000000000000000000);
        liquidityFeesSetup(300, 300, 10);

        _deployDividendTracker(432000, 4000 * (10 ** decimals()), address(this));

        gasForProcessingSetup(300000);
        rewardsFeesSetup(200, 200, 10);
        excludeFromDividends(supplyRecipient, true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(address(dividendTracker), true);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 
        excludeFromFees(address(dividendTracker), true);


        _updateUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(fundAddress, true);
        excludeFromLimits(investedAddress, true);
        excludeFromLimits(address(dividendTracker), true);


        updateTradeCooldownTime(120);

        _mint(supplyRecipient, 1000000000 * (10 ** decimals()));
        _transferOwnership(0x3E02ec7678BD891A30adBC234245D9DFE6Fe37E4);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 7;
    }
    
    function blacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;

        emit BlacklistUpdated(account, isBlacklisted);
    }

    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function fundAddressSetup(address _newAddress) public onlyOwner {
        fundAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit fundAddressUpdated(_newAddress);
    }

    function fundFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        fundFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + fundFees[0] + investedFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + fundFees[1] + investedFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + fundFees[2] + investedFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit fundFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function investedAddressSetup(address _newAddress) public onlyOwner {
        investedAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit investedAddressUpdated(_newAddress);
    }

    function investedFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        investedFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + fundFees[0] + investedFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + fundFees[1] + investedFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + fundFees[2] + investedFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit investedFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        autoBurnFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + fundFees[0] + investedFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + fundFees[1] + investedFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + fundFees[2] + investedFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");
            
        emit autoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns (uint256 leftover) {
        // Sub-optimal method for supplying liquidity
        uint256 halfAmount = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - halfAmount;

        _swapTokensForCoin(halfAmount);

        uint256 coinBalance = address(this).balance;

        (uint amountToken, uint amountETH, uint liquidity) = _addLiquidity(otherHalf, coinBalance);

        emit liquidityAdded(amountToken, amountETH, liquidity);

        return otherHalf - amountToken;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private returns (uint, uint, uint) {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        return uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, lpTokensReceiver, block.timestamp);
    }

    function lpTokensReceiverSetup(address _newAddress) public onlyOwner {
        lpTokensReceiver = _newAddress;

        emit LpTokensReceiverUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        liquidityFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + fundFees[0] + investedFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + fundFees[1] + investedFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + fundFees[2] + investedFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _sendDividends(uint256 tokenAmount) private {
        super._approve(address(this), address(dividendTracker), tokenAmount);

        dividendTracker.distributeDividends(tokenAmount);

        emit rewardsFeeSent(tokenAmount);
    }

    function excludeFromDividends(address account, bool isExcluded) public override onlyOwner {
        dividendTracker.excludeFromDividends(account, balanceOf(account), isExcluded);
    }

    function rewardsFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        rewardsFees = [_buyFee, _sellFee, _transferFee];
        
        totalFees[0] = 0 + fundFees[0] + investedFees[0] + autoBurnFees[0] + liquidityFees[0] + rewardsFees[0];
        totalFees[1] = 0 + fundFees[1] + investedFees[1] + autoBurnFees[1] + liquidityFees[1] + rewardsFees[1];
        totalFees[2] = 0 + fundFees[2] + investedFees[2] + autoBurnFees[2] + liquidityFees[2] + rewardsFees[2];
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
        
        bool canSwap = 0 + _fundPending + _investedPending + _liquidityPending + _rewardsPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _fundPending > 0 || _investedPending > 0) {
                uint256 token2Swap = 0 + _fundPending + _investedPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 fundPortion = coinsReceived * _fundPending / token2Swap;
                (success,) = payable(address(fundAddress)).call{value: fundPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit fundFeeSent(fundAddress, fundPortion);
                _fundPending = 0;

                uint256 investedPortion = coinsReceived * _investedPending / token2Swap;
                (success,) = payable(address(investedAddress)).call{value: investedPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit investedFeeSent(investedAddress, investedPortion);
                _investedPending = 0;

            }

            if (_liquidityPending > 0) {
                _liquidityPending = _swapAndLiquify(_liquidityPending);
            }

            if (_rewardsPending > 0 && getNumberOfDividendTokenHolders() > 0) {
                _sendDividends(_rewardsPending);
                _rewardsPending = 0;
            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(uniswapV2Router) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
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
                
                uint256 autoBurnPortion;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _fundPending += fees * fundFees[txType] / totalFees[txType];

                _investedPending += fees * investedFees[txType] / totalFees[txType];

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

    function _updateUniswapV2Router(address router) private {
        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
        excludeFromDividends(router, true);

        excludeFromLimits(router, true);

        _setAMMPair(uniswapV2Pair, true);

        emit UniswapV2RouterUpdated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != uniswapV2Pair, "DefaultRouter: Cannot remove initial pair from list");

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

    function updateTradeCooldownTime(uint256 _tradeCooldownTime) public onlyOwner {
        require(_tradeCooldownTime <= 7 days, "Antibot: Trade cooldown too long.");
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        require(!blacklisted[from] && !blacklisted[to], "Blacklist: Sender or recipient is blacklisted");

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
        if (AMMPairs[from] && !isExcludedFromLimits[to]) lastTrade[to] = block.timestamp;
        else if (AMMPairs[to] && !isExcludedFromLimits[from]) lastTrade[from] = block.timestamp;

        super._afterTokenTransfer(from, to, amount);
    }
}