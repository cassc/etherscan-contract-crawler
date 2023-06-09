// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/utils/Context.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./IBridge.sol";
import "./IFeeV2.sol";
import "./ILimiter.sol";

abstract contract BridgeBaseV2 is IBridge, Ownable, Pausable, ReentrancyGuard {
    string public name;
    IBridge public prev; // migrate from
    IFeeV2 public fee;
    ILimiter public limiter;
    mapping(bytes32 => bool) private _unlockedCompleted;

    constructor(string memory name_, IBridge prev_, IFeeV2 fee_, ILimiter limiter_) {
        name = name_;
        prev = prev_;
        fee = fee_;
        limiter = limiter_;
    }

    receive() external payable {
        revert();
    }

    function calculateFee(address sender, uint256 amount) public view returns (uint256) {
        if (address(fee) == address(0)) {
            return 0;
        }
        return fee.calculate(sender, amount);
    }

    function setFee(IFeeV2 fee_) external onlyOwner {
        fee = fee_;
    }

    function getLimiterUsage() public view returns (uint256) {
        if (address(limiter) == address(0)) {
            return 0;
        }
        return limiter.getUsage(address(this));
    }

    function isLimited(uint256 amount) public view returns (bool) {
        if (address(limiter) == address(0)) {
            return false;
        }
        return limiter.isLimited(address(this), amount);
    }

    function setLimiter(ILimiter limiter_) external onlyOwner {
        limiter = limiter_;
    }

    function _transferFee(uint256 amount) private nonReentrant {
        uint256 calculatedFee = calculateFee(_msgSender(), amount);
        if (calculatedFee == 0) {
            return;
        }

        require(msg.value >= calculatedFee, "BridgeBase: not enough fee");

        (bool success,) = owner().call{value : msg.value}("");
        require(success, "BridgeBase: can not transfer fee");
    }

    function _checkLimit(uint256 amount) internal {
        if (address(limiter) == address(0)) {
            return;
        }
        limiter.increaseUsage(amount);
    }

    function _beforeLock(uint256 amount) internal whenNotPaused {
        _checkLimit(amount);
        _transferFee(amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isUnlockCompleted(bytes32 hash) public view override returns (bool) {
        if (address(prev) != address(0)) {
            if (prev.isUnlockCompleted(hash)) {
                return true;
            }
        }
        return _unlockedCompleted[hash];
    }

    function _setUnlockCompleted(bytes32 hash) internal {
        require(!isUnlockCompleted(hash), "BridgeBase: already unlocked");
        _unlockedCompleted[hash] = true;
    }
}