// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

import "./Ownable.sol";
import "./zeppelin/ERC20Burnable.sol";

/// @title Lockable token with exceptions
/// @dev Standard burnable ERC20 token modified with pausable transfers.
abstract contract LockableToken is Ownable, ERC20Burnable {

    /// Flag for locking normal trading
    bool public locked = true;

    /// Addresses exempted from token trade lock
    mapping(address => bool) public lockExceptions;

    constructor() {
        // It should always be possible to call reclaimToken
        lockExceptions[address(this)] = true;
    }

    /// @notice Admin function to lock trading
    function lock() external onlyOwner {
        locked = true;
    }

    /// @notice Admin function to unlock trading
    function unlock() external onlyOwner {
        locked = false;
    }

    /// @notice Set whether `sender` may trade when token is locked
    /// @param sender The address to change the lock exception for
    /// @param tradeAllowed Whether `sender` may trade
    function setTradeException(address sender, bool tradeAllowed) external onlyOwner {
        require(sender != address(0), "LockableToken: Invalid address");
        lockExceptions[sender] = tradeAllowed;
    }

    /// @notice Check if the token is currently tradable for `sender`
    /// @param sender The address attempting to make a transfer
    /// @return True if `sender` is allowed to make transfers, false otherwise
    function canTrade(address sender) public view returns(bool) {
        return !locked || lockExceptions[sender];
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotLocked() {
        require(canTrade(msg.sender), "LockableToken: Locked");
        _;
    }

    /// @notice ERC20 transfer only when token is unlocked
    function transfer(address recipient, uint256 amount)
                public override whenNotLocked returns (bool) {
        return super.transfer(recipient, amount);
    }

    /// @notice ERC20 transferFrom only when token is unlocked
    function transferFrom(address from, address to, uint256 value)
                public override whenNotLocked returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /// @notice ERC20 approve only when token is unlocked
    function approve(address spender, uint256 value)
                public override whenNotLocked returns (bool) {
        return super.approve(spender, value);
    }

    /// @notice ERC20 increaseAllowance only when token is unlocked
    function increaseAllowance(address spender, uint256 addedValue)
                public override whenNotLocked returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /// @notice ERC20 decreaseAllowance only when token is unlocked
    function decreaseAllowance(address spender, uint256 subtractedValue)
                public override whenNotLocked returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}