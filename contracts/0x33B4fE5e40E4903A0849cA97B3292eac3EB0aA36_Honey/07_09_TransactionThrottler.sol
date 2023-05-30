// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { Ownable } from "./Ownable.sol";

contract TransactionThrottler is Ownable {
    bool private _initialized;
    bool private _restrictionActive;
    uint256 private _tradingStart;
    uint256 private _maxTransferAmount;
    uint256 private constant _delayBetweenTx = 30;
    mapping(address => uint256) private _previousTx;

    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isUnthrottled;

    event TradingTimeChanged(uint256 tradingTime);
    event RestrictionActiveChanged(bool active);
    event MaxTransferAmountChanged(uint256 maxTransferAmount);
    event MarkedWhitelisted(address indexed account, bool isWhitelisted);
    event MarkedUnthrottled(address indexed account, bool isUnthrottled);

    function initAntibot(uint256 tradingStart) external onlyOwner {
        require(!_initialized, "Protection: Already initialized");
        _initialized = true;
        _restrictionActive = true;
        _tradingStart = tradingStart;
        _maxTransferAmount = 50_000 * 10**18;

        isUnthrottled[owner] = true;

        emit RestrictionActiveChanged(_restrictionActive);
        emit TradingTimeChanged(_tradingStart);
        emit MaxTransferAmountChanged(_maxTransferAmount);
        emit MarkedUnthrottled(owner, true);
    }

    function setTradingStart(uint256 time) external onlyOwner {
        require(_tradingStart > block.timestamp, "Protection: To late");
        _tradingStart = time;
        emit TradingTimeChanged(_tradingStart);
    }

    function setMaxTransferAmount(uint256 amount) external onlyOwner {
        _maxTransferAmount = amount;
        emit MaxTransferAmountChanged(_maxTransferAmount);
    }

    function setRestrictionActive(bool active) external onlyOwner {
        _restrictionActive = active;
        emit RestrictionActiveChanged(_restrictionActive);
    }

    function unthrottleAccount(address account, bool unthrottled) external onlyOwner {
        require(account != address(0), "Zero address");
        isUnthrottled[account] = unthrottled;
        emit MarkedUnthrottled(account, unthrottled);
    }

    function whitelistAccount(address account, bool whitelisted) external onlyOwner {
        require(account != address(0), "Zero address");
        isWhitelisted[account] = whitelisted;
        emit MarkedWhitelisted(account, whitelisted);
    }

    modifier transactionThrottler(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (_restrictionActive && !isUnthrottled[recipient] && !isUnthrottled[sender]) {
            require(block.timestamp >= _tradingStart, "Protection: Transfers disabled");

            if (_maxTransferAmount > 0) {
                require(amount <= _maxTransferAmount, "Protection: Limit exceeded");
            }

            if (!isWhitelisted[recipient]) {
                require(_previousTx[recipient] + _delayBetweenTx <= block.timestamp, "Protection: 30 sec/tx allowed");
                _previousTx[recipient] = block.timestamp;
            }

            if (!isWhitelisted[sender]) {
                require(_previousTx[sender] + _delayBetweenTx <= block.timestamp, "Protection: 30 sec/tx allowed");
                _previousTx[sender] = block.timestamp;
            }
        }
        _;
    }
}