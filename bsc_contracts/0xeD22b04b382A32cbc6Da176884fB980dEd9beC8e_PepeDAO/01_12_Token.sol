/*
https://t.me/ThePepeDAO
Pepe's. A decentralised autonomous organisation set up and lead by BSC community investors.
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./TokenRecover.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract PepeDAO is ERC20, ERC20Burnable, Ownable, TokenRecover {
    
    mapping (address => bool) public blacklisted;

    uint256 public swapThreshold;
    
    uint256 private _marketingPending;
    uint256 private _botPending;
    uint256 private _treasuryPending;
    uint256 private _liquidityPending;

    address public marketingAddress;
    uint16[3] public marketingFees;

    address public botAddress;
    uint16[3] public botFees;

    address public treasuryAddress;
    uint16[3] public treasuryFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxTxAmount;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint256 swapThreshold);

    event marketingAddressUpdated(address marketingAddress);
    event marketingFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event marketingFeeSent(address recipient, uint256 amount);

    event botAddressUpdated(address botAddress);
    event botFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event botFeeSent(address recipient, uint256 amount);

    event treasuryAddressUpdated(address treasuryAddress);
    event treasuryFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event treasuryFeeSent(address recipient, uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountETH, uint liquidity);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UniswapV2RouterUpdated(address indexed uniswapV2Router);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxTxAmountUpdated(uint256 maxTxAmount);
 
    constructor()
        ERC20("PepeDAO", "PEPED") 
    {
        address supplyRecipient = 0xe256856999D367BB1E266047d19Eb28623557EB6;
        
        updateSwapThreshold(50000000 * (10 ** decimals()));

        marketingAddressSetup(0x732770f861f734222082929831d9c61F7A238137);
        marketingFeesSetup(200, 200, 0);

        botAddressSetup(0x626B4A0C5CEd552af0136f4c03C43eA5809D0461);
        botFeesSetup(500, 500, 0);

        treasuryAddressSetup(0xD93E2f303dfD30bAA8073A7E9546a0D376C5447C);
        treasuryFeesSetup(200, 200, 0);

        lpTokensReceiverSetup(0x163864fac67967ab78552c922aFA18e307CD8009);
        liquidityFeesSetup(100, 100, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(marketingAddress, true);
        excludeFromLimits(botAddress, true);
        excludeFromLimits(treasuryAddress, true);

        updateMaxWalletAmount(2000000000 * (10 ** decimals()));

        updateMaxTxAmount(1000000000 * (10 ** decimals()));

        _mint(supplyRecipient, 100000000000 * (10 ** decimals()));
        _transferOwnership(0xe256856999D367BB1E266047d19Eb28623557EB6);
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
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
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

        totalFees[0] = 0 + marketingFees[0] + botFees[0] + treasuryFees[0] + liquidityFees[0];
        totalFees[1] = 0 + marketingFees[1] + botFees[1] + treasuryFees[1] + liquidityFees[1];
        totalFees[2] = 0 + marketingFees[2] + botFees[2] + treasuryFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit marketingFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function botAddressSetup(address _newAddress) public onlyOwner {
        botAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit botAddressUpdated(_newAddress);
    }

    function botFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        botFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + marketingFees[0] + botFees[0] + treasuryFees[0] + liquidityFees[0];
        totalFees[1] = 0 + marketingFees[1] + botFees[1] + treasuryFees[1] + liquidityFees[1];
        totalFees[2] = 0 + marketingFees[2] + botFees[2] + treasuryFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit botFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function treasuryAddressSetup(address _newAddress) public onlyOwner {
        treasuryAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit treasuryAddressUpdated(_newAddress);
    }

    function treasuryFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        treasuryFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + marketingFees[0] + botFees[0] + treasuryFees[0] + liquidityFees[0];
        totalFees[1] = 0 + marketingFees[1] + botFees[1] + treasuryFees[1] + liquidityFees[1];
        totalFees[2] = 0 + marketingFees[2] + botFees[2] + treasuryFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit treasuryFeesUpdated(_buyFee, _sellFee, _transferFee);
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

        totalFees[0] = 0 + marketingFees[0] + botFees[0] + treasuryFees[0] + liquidityFees[0];
        totalFees[1] = 0 + marketingFees[1] + botFees[1] + treasuryFees[1] + liquidityFees[1];
        totalFees[2] = 0 + marketingFees[2] + botFees[2] + treasuryFees[2] + liquidityFees[2];
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
        
        bool canSwap = 0 + _marketingPending + _botPending + _treasuryPending + _liquidityPending >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _marketingPending > 0 || _botPending > 0 || _treasuryPending > 0) {
                uint256 token2Swap = 0 + _marketingPending + _botPending + _treasuryPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 marketingPortion = coinsReceived * _marketingPending / token2Swap;
                (success,) = payable(address(marketingAddress)).call{value: marketingPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit marketingFeeSent(marketingAddress, marketingPortion);
                _marketingPending = 0;

                uint256 botPortion = coinsReceived * _botPending / token2Swap;
                (success,) = payable(address(botAddress)).call{value: botPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit botFeeSent(botAddress, botPortion);
                _botPending = 0;

                uint256 treasuryPortion = coinsReceived * _treasuryPending / token2Swap;
                (success,) = payable(address(treasuryAddress)).call{value: treasuryPortion}("");
                require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                emit treasuryFeeSent(treasuryAddress, treasuryPortion);
                _treasuryPending = 0;

            }

            if (_liquidityPending > 0) {
                _liquidityPending = _swapAndLiquify(_liquidityPending);
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
                
                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _marketingPending += fees * marketingFees[txType] / totalFees[txType];

                _botPending += fees * botFees[txType] / totalFees[txType];

                _treasuryPending += fees * treasuryFees[txType] / totalFees[txType];

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateUniswapV2Router(address router) private {
        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
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

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        require(!blacklisted[from] && !blacklisted[to], "Blacklist: Sender or recipient is blacklisted");

        if (AMMPairs[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        if (!AMMPairs[to] && !isExcludedFromLimits[from]) { // OTHER
            require(amount <= maxTxAmount, "MaxTx: Cannot exceed max transfer limit");
        }
    
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