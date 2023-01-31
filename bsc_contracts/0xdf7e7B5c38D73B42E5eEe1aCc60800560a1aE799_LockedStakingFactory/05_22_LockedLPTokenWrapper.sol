pragma solidity ^0.5.0;

import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/SafeERC20.sol";

contract LockedLPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public uni;

    constructor (address _uni) public {
        uni = IERC20(_uni);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _unlockTime;
    mapping(address => uint256) private _lastLockDuration; // This is stored in days not seconds


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function unlocksAt(address account) public view returns (uint256) {
        return _unlockTime[account];
    }

    function latestLockDuration(address account) public view returns (uint256) {
        return _lastLockDuration[account];
    }

    function stakeOnBehalf(address user, uint256 amount, uint256 duration) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
        // Incase user has no locked up tokens
        if(_unlockTime[user] <= block.timestamp) {
            _lastLockDuration[user] = duration;
        // Incase user currently has tokens locked up
        } else {
            if(_lastLockDuration[user] < duration)
                _lastLockDuration[user] = duration; // If the lock duration previously was lower, allow to lock duration to be increased, lock duration cannot be reduced.
        }
        uint256 durationInSeconds = _lastLockDuration[user].mul(1 days);
        _unlockTime[user] = block.timestamp.add(durationInSeconds); // The duration for lock resets each time user stakes
        uni.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        require(_unlockTime[msg.sender] <= block.timestamp, "Cannot unlock tokens yet");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uni.safeTransfer(msg.sender, amount);
    }
}