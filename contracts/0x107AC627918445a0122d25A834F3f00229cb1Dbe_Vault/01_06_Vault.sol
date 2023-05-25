pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error InvalidLockingDuration();
error ZeroAddressToken();
error InvalidAmount();
error NoDeposit();
error TokensLocked();
error CannotExtendLocking();
error InvalidUnlockingTimestamp();
error InvalidAccount();
error NeedsLockingRenewal();
error CannotRecoverLockableToken();
error NoTokensToRecover();

/**
 * @title Vault
 * @dev Vault contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract Vault is Ownable {
    using SafeERC20 for IERC20;

    struct Deposit {
        uint256 amount;
        uint256 unlockingTimestamp;
    }

    uint256 public lockingDuration;
    mapping(address => Deposit) public userDeposit;
    address public token;

    event LockingDurationUpdated(uint256 duration);
    event UnlockingTimestampUpdated(address user, uint256 unlockingTimestamp);
    event Deposited(address user, uint256 amount, uint256 unlockingTimestamp);
    event Withdrawn(address user, uint256 amount);
    event LockingRenewed(address user, uint256 unlockingTimestamp);
    event ERC20Recovered(address token, uint256 amount);

    constructor(address _token, uint256 _lockingDuration) {
        if (_token == address(0)) revert ZeroAddressToken();
        if (_lockingDuration == 0) revert InvalidLockingDuration();
        token = _token;
        lockingDuration = _lockingDuration;
    }

    function updateLockingDuration(uint256 _duration) external onlyOwner {
        if (_duration == 0) revert InvalidLockingDuration();
        lockingDuration = _duration;
        emit LockingDurationUpdated(_duration);
    }

    function updateUnlockingTimestamp(
        address _account,
        uint256 _unlockingTimestamp
    ) external onlyOwner {
        if (_unlockingTimestamp < block.timestamp)
            revert InvalidUnlockingTimestamp();
        Deposit storage _deposit = userDeposit[_account];
        if (_deposit.amount == 0) revert InvalidAccount();
        if (_unlockingTimestamp > _deposit.unlockingTimestamp)
            revert CannotExtendLocking();
        _deposit.unlockingTimestamp = _unlockingTimestamp;
        emit UnlockingTimestampUpdated(_account, _unlockingTimestamp);
    }

    function recoverERC20(address _tokenToRecover) external onlyOwner {
        if (_tokenToRecover == token) revert CannotRecoverLockableToken();
        uint256 _tokenBalance = IERC20(_tokenToRecover).balanceOf(
            address(this)
        );
        if (_tokenBalance == 0) revert NoTokensToRecover();
        IERC20(_tokenToRecover).safeTransfer(owner(), _tokenBalance);
        emit ERC20Recovered(_tokenToRecover, _tokenBalance);
    }

    function deposit(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        Deposit storage _deposit = userDeposit[msg.sender];
        _deposit.amount += _amount;
        if (_deposit.unlockingTimestamp == 0)
            _deposit.unlockingTimestamp = block.timestamp + lockingDuration;
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount, _deposit.unlockingTimestamp);
    }

    function withdraw(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        Deposit storage _deposit = userDeposit[msg.sender];
        if (_deposit.unlockingTimestamp > block.timestamp)
            revert TokensLocked();
        _deposit.amount -= _amount;
        if(_deposit.amount == 0) _deposit.unlockingTimestamp = 0;
        IERC20(token).safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function renewLocking() external {
        Deposit storage _deposit = userDeposit[msg.sender];
        if (_deposit.unlockingTimestamp == 0) revert NoDeposit();
        uint256 _unlockingTimestamp = (
            _deposit.unlockingTimestamp > block.timestamp
                ? _deposit.unlockingTimestamp
                : block.timestamp
        ) + lockingDuration;
        _deposit.unlockingTimestamp = _unlockingTimestamp;
        emit LockingRenewed(msg.sender, _unlockingTimestamp);
    }

    function renewedUnlockingTimestamp(address _account)
        external
        view
        returns (uint256)
    {
        Deposit storage _deposit = userDeposit[_account];
        if (_deposit.unlockingTimestamp == 0) revert NoDeposit();
        return
            (
                _deposit.unlockingTimestamp > block.timestamp
                    ? _deposit.unlockingTimestamp
                    : block.timestamp
            ) + lockingDuration;
    }
}