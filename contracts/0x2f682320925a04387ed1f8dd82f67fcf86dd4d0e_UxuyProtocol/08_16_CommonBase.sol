//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./CallerControl.sol";
import "./SafeNativeAsset.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract CommonBase is Ownable, Pausable, CallerControl, ReentrancyGuard {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    uint256 internal constant TRON_CHAIN_ID = 0x1ebf88508a03865c71d452e25f4d51194196a1d22b6653dc;

    // The original address of this contract
    address private immutable _original;

    // ERC20 safeTransfer function pointer
    function(IERC20, address, uint256) internal _safeTransferERC20;

    // @dev Emitted when native assets (token=address(0)) or tokens are withdrawn by owner.
    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    constructor() {
        _original = address(this);
        if (block.chainid == TRON_CHAIN_ID) {
            _safeTransferERC20 = SafeERC20.safeTransferTron;
        } else {
            _safeTransferERC20 = SafeERC20.safeTransfer;
        }
    }

    // @dev prevents delegatecall into the modified method
    modifier noDelegateCall() {
        _checkNotDelegateCall();
        _;
    }

    // @dev check whether deadline is reached
    modifier checkDeadline(uint256 deadline) {
        require(deadline == 0 || block.timestamp <= deadline, "CommonBase: transaction too old");
        _;
    }

    // @dev fallback function to receive native assets
    receive() external payable {}

    // @dev pause stops contract from doing any swap
    function pause() external onlyOwner {
        _pause();
    }

    // @dev resumes contract to do swap
    function unpause() external onlyOwner {
        _unpause();
    }

    // @dev withdraw eth to recipient
    function withdrawNativeAsset(uint256 amount, address recipient) external onlyOwner {
        recipient.safeTransfer(amount);
        emit Withdrawn(address(0), recipient, amount);
    }

    // @dev withdraw token to owner account
    function withdrawToken(address token, uint256 amount, address recipient) external onlyOwner {
        _safeTransferERC20(IERC20(token), recipient, amount);
        emit Withdrawn(token, recipient, amount);
    }

    // @dev update caller allowed status
    function updateAllowedCaller(address caller, bool allowed) external onlyOwner {
        _updateAllowedCaller(caller, allowed);
    }

    // @dev ensure not a delegatecall
    function _checkNotDelegateCall() private view {
        require(address(this) == _original, "CommonBase: delegate call not allowed");
    }
}