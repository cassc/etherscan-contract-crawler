/*

//  ________  _______   ______  ________  __    __  _______    ______   __    __  ______  _______    ______  
// /        |/       \ /      |/        |/  \  /  |/       \  /      \ /  |  /  |/      |/       \  /      \ 
// $$$$/ $$$$  |$$$/ $$$$/ $  \ $ |$$$$  |/$$$  |$ |  $ |$$$/ $$$$  |/$$$  |
// $ |__    $ |__$ |  $ |  $ |__    $$  \$ |$ |  $ |$ |  $/ $ |__$ |  $ |  $ |__$ |$ \__$/ 
// $    |   $    $<   $ |  $    |   $$  $ |$ |  $ |$ |      $    $ |  $ |  $    $/ $      \ 
// $$$/    $$$$  |  $ |  $$$/    $ $ $ |$ |  $ |$ |   __ $$$$ |  $ |  $$$$/   $$$  |
// $ |      $ |  $ | _$ |_ $ |_____ $ |$$ |$ |__$ |$ \__/  |$ |  $ | _$ |_ $ |      /  \__$ |
// $ |      $ |  $ |/ $   |$       |$ | $$ |$    $/ $    $/ $ |  $ |/ $   |$ |      $    $/ 
// $/       $/   $/ $$$/ $$$$/ $/   $/ $$$$/   $$$/  $/   $/ $$$/ $/        $$$/  
                                                                                                                             
// The Mutual Fund of Friend Tech

// Friendchips gives you exposure to the Friend Tech ecosystem and airdrop, without all the hard work.
// We manage the bridging and buying, we all share the rewards.

// website - https://www.friendchips.tech/
// Telegram - https://t.me/friendchipstoken
// Twitter - https://twitter.com/FriendChipsSoFi

*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract FriendChips_SoFi is ERC20, ERC20Burnable, Ownable, Initializable {
    
    uint256 public swapThreshold;
    
    uint256 private _keytaxPending;

    address public keytaxAddress;
    uint16[3] public keytaxFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event keytaxAddressUpdated(address keytaxAddress);
    event keytaxFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event keytaxFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"FriendChips SoFi", unicode"FC") 
    {
        address supplyRecipient = 0xcB5c03908CF1c02F2f6807CFDA7Ea1bB4286e72A;
        
        updateSwapThreshold(610000 * (10 ** decimals()) / 10);

        keytaxAddressSetup(0x2C6CCD3b671501c6E1a0E586Ae94e085F964E8F3);
        keytaxFeesSetup(1000, 1000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 
        _excludeFromLimits(keytaxAddress, true);

        updateMaxWalletAmount(61000000 * (10 ** decimals()) / 10);

        updateMaxBuyAmount(18300000 * (10 ** decimals()) / 10);
        updateMaxSellAmount(18300000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 1220000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xcB5c03908CF1c02F2f6807CFDA7Ea1bB4286e72A);
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
        return 0 + _keytaxPending;
    }

    function keytaxAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesDefaultRouterWallet: Wallet tax recipient cannot be a 0x0 address");

        keytaxAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit keytaxAddressUpdated(_newAddress);
    }

    function keytaxFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - keytaxFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - keytaxFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - keytaxFees[2] + _transferFee;
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        keytaxFees = [_buyFee, _sellFee, _transferFee];

        emit keytaxFeesUpdated(_buyFee, _sellFee, _transferFee);
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
            
            if (false || _keytaxPending > 0) {
                uint256 token2Swap = 0 + _keytaxPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 keytaxPortion = coinsReceived * _keytaxPending / token2Swap;
                if (keytaxPortion > 0) {
                    success = payable(keytaxAddress).send(keytaxPortion);
                    if (success) {
                        emit keytaxFeeSent(keytaxAddress, keytaxPortion);
                    }
                }
                _keytaxPending = 0;

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
                
                _keytaxPending += fees * keytaxFees[txType] / totalFees[txType];

                
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

    function _maxTxSafeLimit() private view returns (uint256) {
        return totalSupply() * 5 / 10000;
    }

    function updateMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        require(_maxBuyAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(_maxSellAmount >= _maxTxSafeLimit(), "MaxTx: Limit too low");
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (AMMPairs[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (AMMPairs[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
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