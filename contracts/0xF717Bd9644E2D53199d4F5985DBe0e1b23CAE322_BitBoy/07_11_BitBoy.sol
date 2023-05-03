// SPDX-License-Identifier: UNLICENSED

/*
 * BitBoy 
 * App:             https://bitboycrypto.vip
 * Twitter:         https://twitter.com/BitBoyCoinEth
 * Telegram:        https://t.me/BitBoyChat
 */

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "uniswap/uniswap-contracts-moonbeam/contracts/core/interfaces/IUniswapV2Factory.sol";
import "uniswap/uniswap-contracts-moonbeam/contracts/core/interfaces/IUniswapV2Pair.sol";
import "uniswap/uniswap-contracts-moonbeam/contracts/periphery/interfaces/IUniswapV2Router01.sol";
import "uniswap/uniswap-contracts-moonbeam/contracts/periphery/interfaces/IUniswapV2Router02.sol";

contract BitBoy is ERC20, ERC20Burnable, Ownable {
    
    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxWalletAmount;

    mapping (address => uint256) public lastTrade;
    uint256 public tradeCooldownTime;

    bool public initial;
    address public supplyRecipient;
    address public router;
    
    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxWalletAmountUpdated(uint256 maxWalletAmount);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);
 
    constructor(address _supplyRecipient, address _router)
        ERC20("$BitBoy", "$BITBOY") 
    {
        supplyRecipient = _supplyRecipient;
        router = _router;
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function initialSetup() public onlyOwner {
        require(!initial, "Initial Setup: The contract has already been started with its default values");

        _updateRouterV2(router);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 

        updateMaxWalletAmount(126207126207126 * (10 ** decimals()));

        updateTradeCooldownTime(30);

        _mint(supplyRecipient, 420690420690420 * (10 ** decimals()));

        initial = true;
    }
    
    function _updateRouterV2(address _router) private {
        routerV2 = IUniswapV2Router02(_router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(_router, true);

        _setAMMPair(pairV2, true);

        emit RouterV2Updated(_router);
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

    function updateTradeCooldownTime(uint256 _tradeCooldownTime) public onlyOwner {
        require(_tradeCooldownTime <= 7 days, "Antibot: Trade cooldown too long.");
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if(!isExcludedFromLimits[from]){
            require(lastTrade[from] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction sender is in anti-bot cooldown");
        }
        if(!isExcludedFromLimits[to]){
            require(lastTrade[to] + tradeCooldownTime <= block.timestamp, "Antibot: Transaction recipient is in anti-bot cooldown");
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

        if (AMMPairs[from] && !isExcludedFromLimits[to]) lastTrade[to] = block.timestamp;
        else if (AMMPairs[to] && !isExcludedFromLimits[from]) lastTrade[from] = block.timestamp;

        super._afterTokenTransfer(from, to, amount);
    }
}