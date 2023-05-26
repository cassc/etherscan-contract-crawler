// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Killable.sol";

abstract contract TradeValidator is Ownable, Killable {

    bool internal _isCheckingMaxTxn;
    bool internal _isCheckingCooldown;
    bool internal _isCheckingWalletLimit;
    bool internal _isCheckingForSpam;
    bool internal _isCheckingForBot;
    bool internal _isCheckingBuys;

    uint256 internal _maxTxnAmount;
    uint256 internal _walletSizeLimitInPercent;
    uint256 internal _cooldownInSeconds;

    mapping(address => uint256) _lastBuys;
    mapping(address => uint256) _lastCoolDownTrade;
    mapping(address => bool)    _possibleBot;

    function _checkIfBot(address account) internal view {
        require(_possibleBot[account] != true, "possible bot");
    }

    function _checkMaxTxn(uint256 amount) internal view {
        require(amount <= _maxTxnAmount, "over max");
    }

    function _checkCooldown(address recipient) internal {
        require(block.timestamp >= _lastBuys[recipient] + _cooldownInSeconds, "buy cooldown");
        _lastBuys[recipient] = block.timestamp;
    }

    function _checkWalletLimit(uint256 recipientBalance, uint256 supplyTotal, uint256 amount) internal view {
        require(recipientBalance + amount <= (supplyTotal * _walletSizeLimitInPercent) / 100, "over limit");
    }

    function _checkForSpam(address pair, address to, address from) internal {
        bool disallow;
        // Disallow multiple same source trades in same block
        if (from == pair) {
            disallow = _lastCoolDownTrade[to] == block.number || _lastCoolDownTrade[tx.origin] == block.number;
            _lastCoolDownTrade[to] = block.number;
            _lastCoolDownTrade[tx.origin] = block.number;
        } else if (to == pair) {
            disallow = _lastCoolDownTrade[from] == block.number || _lastCoolDownTrade[tx.origin] == block.number;
            _lastCoolDownTrade[from] = block.number;
            _lastCoolDownTrade[tx.origin] = block.number;
        }
        require(!disallow, "Multiple trades in same block from same source are not allowed during trading start cooldown");
    }

    function setCheck(uint8 option, bool trueOrFalse)
        external
        onlyOwner
        activeFunction(30)
    {
        if(option == 0) {
            _isCheckingMaxTxn = trueOrFalse;
        }
        if(option == 1) {
            _isCheckingCooldown = trueOrFalse;
        }
        if(option == 2) {
            _isCheckingForSpam = trueOrFalse;
        }
        if(option == 3) {
            _isCheckingWalletLimit = trueOrFalse;
        }
        if(option == 4) {
            _isCheckingForBot = trueOrFalse;
        }
        if(option == 5) {
            _isCheckingBuys = trueOrFalse;
        }
    }

    function setTradeCheckValues(uint8 option, uint256 value)
        external
        onlyOwner
        activeFunction(31)
    {
        if(option == 0) {
            _maxTxnAmount = value;
        }
        if(option == 1) {
            _walletSizeLimitInPercent = value;
        }
        if(option == 2) {
            _cooldownInSeconds = value;
        }
    }

    function setPossibleBot(address account, bool trueOrFalse)
        external
        onlyOwner
        activeFunction(32)
    {
        _possibleBot[account] = trueOrFalse;
    }
}