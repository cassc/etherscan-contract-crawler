// deployscript 5107fcb7552eafd7f45e5d52da8b277e6844dc1b
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Errors.sol";
import "BaseVersion.sol";

/// @dev Our version of OpenZeppelin OwnableUpgradeable can be used by proxy and non-proxy.
abstract contract BaseOwnable is BaseVersion {
    address public owner;
    address public pendingOwner;
    bool private initialized = false;

    event PendingOwnerSet(address to);
    event NewOwnerSet(address owner);

    /// @dev `owner` is set by argument, thus the owner can any address.
    constructor(address _owner) {
        initialize(_owner);
    }

    /// @dev If the contract is a proxy, `initialize` can be called to claim the ownership.
    ///      This function can be called only once.
    function initialize(address _owner) public {
        require(!initialized, Errors.ALREADY_INITIALIZED);
        _setOwner(_owner);
        initialized = true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, Errors.CALLER_IS_NOT_OWNER);
        _;
    }

    function setPendingOwner(address to) external onlyOwner {
        pendingOwner = to;
        emit PendingOwnerSet(pendingOwner);
    }

    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
    }

    /// @notice User should ensure the corrent owner address set, or the
    /// ownership may be transferred to blackhole. It is recommended to
    /// take a safer way with setPendingOwner() + acceptOwner().
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New Owner is zero");
        _setOwner(newOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        _setOwner(pendingOwner);
    }

    /// @dev Clear pendingOwner to prevent it from reclaiming the owner.
    function _setOwner(address _owner) internal {
        owner = _owner;
        pendingOwner = address(0);
        emit NewOwnerSet(owner);
    }
}