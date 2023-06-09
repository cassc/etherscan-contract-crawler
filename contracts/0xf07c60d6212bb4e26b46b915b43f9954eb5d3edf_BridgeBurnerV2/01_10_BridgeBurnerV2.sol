// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./IWrappedToken.sol";
import "./IFeeV2.sol";
import "./BridgeBaseV2.sol";

contract BridgeBurnerV2 is BridgeBaseV2 {
    IWrappedToken public token;

    constructor(
        IWrappedToken token_,
        string memory name,
        IBridge prev,
        IFeeV2 fee,
        ILimiter limiter
    ) BridgeBaseV2(name, prev, fee, limiter) {
        token = token_;
    }

    function lock(uint256 amount) external payable override {
        _beforeLock(amount);
        token.burnFrom(_msgSender(), amount);
        emit Locked(_msgSender(), amount);
    }

    function unlock(address account, uint256 amount, bytes32 hash) external override onlyOwner {
        _setUnlockCompleted(hash);
        token.mint(account, amount);
        emit Unlocked(account, amount);
    }

    function renounceOwnership() public override onlyOwner {
        _pause();
        Ownable.renounceOwnership();
    }
}