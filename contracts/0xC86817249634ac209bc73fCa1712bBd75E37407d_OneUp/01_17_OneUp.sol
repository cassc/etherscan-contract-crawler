//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';


contract OneUp is ERC20PresetMinterPauser, Ownable {
    using SafeMath for uint256;

    uint256 public tradingTime;
    uint256 public restrictionLiftTime;

    // Users need to wait this time for doing next transaction, after restricted time finish
    uint256 public delayBetweenTx = 30 seconds;

    uint256 public constant MAX_ALLOWED_TOKENS = 240000 ether;
    uint256 public constant MAX_SUPPLY = 100000000 ether;
    uint256 public constant RESTRICTED_TRANSFER_DELAY = 15 minutes;

    // Token holder > timestamp of the last transaction
    mapping (address => uint256) private _lastTx;

    // Addresses/contracts without time restrictions (Uniswap, Vesting and etc)
    mapping (address => bool) private _isWhitelisted;

    // Anti-bot solution
    modifier launchRestrict(address from, address to, uint256 amount) {
        // If trading time does not reached
        if (block.timestamp < tradingTime) {
            require(_isWhitelisted[from] || _isWhitelisted[to], 'launchRestrict: Transfers are disabled!');
        }

        // After trading time reached
        else if (block.timestamp >= tradingTime) {
            uint256 requiredDelay;

            // During the first restricted period tokens amount are limited
            if (block.timestamp < restrictionLiftTime) {
                require(amount <= MAX_ALLOWED_TOKENS, 'launchRestrict: Amount greater than max limit');
                 // During this period delay should be 60 seconds
                requiredDelay = 60 seconds;
            } else {
                requiredDelay = delayBetweenTx;
            }

            // If no one whitelisted, update data for both
            if (!_isWhitelisted[from] && !_isWhitelisted[to]) {
                require(_lastTx[from].add(requiredDelay) <= block.timestamp && _lastTx[to].add(requiredDelay) <= block.timestamp, 'launchRestrict: Only one tx/min in restricted mode!');

                _lastTx[from] = block.timestamp;
                _lastTx[to] = block.timestamp;
            }

            // If recipient not whitelisted, update data for recipient
            else if (!_isWhitelisted[to]){
                require(_lastTx[to].add(requiredDelay) <= block.timestamp, 'launchRestrict: Only one tx/min in restricted mode!');

                _lastTx[to] = block.timestamp;
            }

            // If sender not whitelisted, update data for sender
            else if (!_isWhitelisted[from]) {
                require(_lastTx[from].add(requiredDelay) <= block.timestamp, 'launchRestrict: Only one tx/min in restricted mode!');

                _lastTx[from] = block.timestamp;
            }
        }
        _;
    }

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor () ERC20PresetMinterPauser('1-UP', '1-UP') {
        // Silence
    }

    // ------------------------
    // SETTERS (OWNABLE)
    // ------------------------

    function setTradingStart(uint256 time) external {
        require(tradingTime == 0, 'setTradingStart: Already saved!');
        require(hasRole(MINTER_ROLE, _msgSender()), 'setTradingStart: Must have minter role to set start time!');

        tradingTime = time;
        restrictionLiftTime = tradingTime.add(RESTRICTED_TRANSFER_DELAY);
    }

    function whitelistAccount(address account) external onlyOwner {
        _isWhitelisted[account] = true;
    }

    function removeWhitelistedAccount(address account) external onlyOwner {
        _isWhitelisted[account] = false;
    }

    function decreaseDelayBetweenTx(uint256 newDelay) external onlyOwner {
        require(newDelay < delayBetweenTx, 'decreaseDelayBetweenTx: New delay should be less from previous amount!');

        delayBetweenTx = newDelay;
    }

    // ------------------------
    // GETTERS
    // ------------------------

    function lastTx(address account) external view returns (uint256) {
        return _lastTx[account];
    }

    function isWhitelisted(address account) external view returns (bool) {
        return _isWhitelisted[account];
    }

    // ------------------------
    // INTERNAL
    // ------------------------

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= MAX_SUPPLY, '_mint: Cap exceeded!');

        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal launchRestrict(from, to, amount) virtual override(ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }
}