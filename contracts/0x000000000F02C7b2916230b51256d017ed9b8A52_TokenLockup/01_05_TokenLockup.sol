// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Bartrr Token Lockup Contract
/// @notice This contract is used to lockup tokens for a specified period of time
contract TokenLockup is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private idCounter;

    /// @notice Emitted when tokens are locked up
    /// @param lockupId Id of the lockup
    /// @param token Address of the token being unlocked
    /// @param amount Amount of token being unlocked
    /// @param endTime Time at which the token can be unlocked
    event TokensLocked(
        uint256 indexed lockupId,
        address indexed token,
        uint256 amount,
        uint256 duration,
        uint256 endTime
    );

    /// @notice Emitted when tokens are unlocked
    /// @param lockupId Id of the lockup
    /// @param token Address of the token being unlocked
    /// @param amount Amount of token being unlocked
    event TokensUnlocked(
        uint256 indexed lockupId,
        address indexed token,
        uint256 amount
    );

    struct Lockup {
        address owner;
        address token;
        uint256 amount;
        uint256 endTime;
        bool isLocked;
    }

    mapping(uint256 => Lockup) public lockups; // mapping of lockups
    mapping(address => uint256[]) public userLockups;

    /// @notice Lock tokens for a period of time
    /// @param _token address of the token to lock
    /// @param _amount amount of tokens to lock
    /// @param _duration time in seconds until the lockup expires
    function lockTokens(
        address _token,
        uint256 _amount,
        uint256 _duration
    ) external payable {
        require(_duration <= 50 * 365 days, "Lockup must be 50 years or less"); // 50 years

        if (_token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            require(msg.value == _amount, "Amount must match msg.value");
        } else {
            require(
                IERC20(_token).balanceOf(msg.sender) >= _amount,
                "Insufficient balance"
            );
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        Lockup memory lockup = Lockup(
            msg.sender,
            _token,
            _amount,
            block.timestamp + _duration,
            true
        );
        lockups[idCounter] = lockup;
        userLockups[msg.sender].push(idCounter);

        emit TokensLocked(
            idCounter,
            _token,
            _amount,
            _duration,
            block.timestamp + _duration
        );

        idCounter++;
    }

    /// @notice Unlocks the tokens
    /// @param _lockupId id of the lockup to unlock
    function unlockTokens(uint256 _lockupId) external nonReentrant {
        Lockup memory lockup = lockups[_lockupId];
        require(lockup.owner == msg.sender, "Only the owner can unlock tokens");
        require(lockup.endTime <= block.timestamp, "Lockup not complete");
        require(lockup.isLocked, "Lockup already redeemed");

        lockups[_lockupId].isLocked = false;

        if (
            lockup.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            _transfer(payable(msg.sender), lockup.amount);
        } else {
            IERC20(lockup.token).safeTransfer(msg.sender, lockup.amount);
        }

        emit TokensUnlocked(_lockupId, lockup.token, lockup.amount);
    }

    /// @notice Function to transfer Ether from this contract to address from input
    /// @param _to address of transfer recipient
    /// @param _amount amount of ether to be transferred
    function _transfer(address payable _to, uint256 _amount) internal {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}