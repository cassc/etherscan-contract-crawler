// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AntiBot is Ownable {

    bool private initialized;
    bool private restrictionActive;

    uint256 public startTimestamp;
    uint256 public transferMaxValue;
    uint256 public transferMinDelay;

    mapping(address => bool) internal _isWhitelisted;
    mapping(address => bool) internal _isUnthrottled;
    mapping(address => uint256) internal _lastTimestamp;

    event StartTimestampChanged(uint256 timestamp);
    event RestrictionActiveChanged(bool active);
    event TransferMaxValueChanged(uint256 maxValue);
    event TransferMinDelayChanged(uint256 minDelay);
    event MarkedWhitelisted(address indexed account, bool isWhitelisted);
    event MarkedUnthrottled(address indexed account, bool isUnthrottled);

    function initAntibot(uint256 tradingStart, uint256 maxValue, uint256 minDelay) public onlyOwner() {
        require(!initialized, "Antibot: Already initialized");
        initialized = true;
        whitelistAccount(owner(), true);
        setStartTimestamp(tradingStart);
        setTransferMaxValue(maxValue);
        setTransferMinDelay(minDelay);
        setRestrictionActive(true);
    }

    function setStartTimestamp(uint256 _time) public onlyOwner() {
        require(startTimestamp == 0 || startTimestamp > block.timestamp, "Antibot: Too late");
        startTimestamp = _time;
        emit StartTimestampChanged(startTimestamp);
    }

    function setTransferMaxValue(uint256 _value) public onlyOwner() {
        transferMaxValue = _value;
        emit TransferMaxValueChanged(transferMaxValue);
    }

    function setTransferMinDelay(uint256 _delay) public onlyOwner() {
        transferMinDelay = _delay;
        emit TransferMinDelayChanged(transferMinDelay);
    }

    function setRestrictionActive(bool _active) public onlyOwner() {
        restrictionActive = _active;
        emit RestrictionActiveChanged(restrictionActive);
    }

    function unthrottleAccount(address _account, bool _unthrottled) public onlyOwner() {
        require(_account != address(0), "Zero address");
        _isUnthrottled[_account] = _unthrottled;
        emit MarkedUnthrottled(_account, _unthrottled);
    }

    function isUnthrottled(address account) public view returns (bool) {
        return _isUnthrottled[account];
    }

    function whitelistAccount(address _account, bool _whitelisted) public onlyOwner() {
        require(_account != address(0), "Zero address");
        _isWhitelisted[_account] = _whitelisted;
        emit MarkedWhitelisted(_account, _whitelisted);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }

    modifier transferThrottler(address sender, address target, uint256 amount) {
        if (restrictionActive && !_isWhitelisted[target] && !_isWhitelisted[sender]) {
            require(block.timestamp >= startTimestamp, "Antibot: Transfers disabled");
            
            if (transferMaxValue > 0) {
                require(amount <= transferMaxValue, "Antibot: Limit exceeded");
            }

            if (!_isUnthrottled[target]) {
                require(_lastTimestamp[target] + transferMinDelay <= block.timestamp, "Antibot: too many transactions, try in a moment!");
                _lastTimestamp[target] = block.timestamp;
            }

            if (!_isUnthrottled[sender]) {
                require(_lastTimestamp[sender] + transferMinDelay <= block.timestamp, "Antibot: too many transactions, try in a moment!");
                _lastTimestamp[sender] = block.timestamp;
            }
        }
        _;
    }
}