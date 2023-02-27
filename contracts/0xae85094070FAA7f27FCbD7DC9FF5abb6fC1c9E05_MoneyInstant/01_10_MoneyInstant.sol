// SPDX-License-Identifier: MIT

// File: MoneyInstant.sol

pragma solidity 0.8.17;

// Libs Dependencies
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Protocol Components
import './IMoneyInstant.sol';
import './Types.sol';

/**
 * @title MoneyInstant
 * @notice MoneyInstant implementation for ERC20 tokens.
 */
contract MoneyInstant is IMoneyInstant, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => uint256)) private userToTokens;

    mapping(address => uint256) private userToNative;

    function createInstantTransfer(
        string calldata id,
        address tokenAddress,
        Types.Payment[] memory payments
    ) external {
        require(payments.length > 0, 'no any payments');

        uint256 totalDeposit;
        for (uint256 i = 0; i < payments.length; i++) {
            address recipient = payments[i].recipient;
            require(
                recipient != address(0x00),
                'cannot send to the zero address'
            );
            require(
                recipient != address(this),
                'cannot send to the contract itself'
            );
            require(
                recipient != msg.sender,
                'cannot send to the caller address'
            );

            uint256 deposit = payments[i].deposit;
            require(deposit > 0, 'deposit is zero');

            totalDeposit += deposit;
            userToTokens[recipient][tokenAddress] += deposit;
        }
        emit InstantTransfer(id, msg.sender, tokenAddress, totalDeposit);
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            totalDeposit
        );
    }

    function withdrawInstant(address tokenAddress, uint256 amount)
        external
        nonReentrant
    {
        require(amount > 0, 'amount is zero');
        uint256 balance = userToTokens[msg.sender][tokenAddress];
        require(balance >= amount, 'amount exceeds the available balance');
        unchecked {
            userToTokens[msg.sender][tokenAddress] = balance - amount;
        }
        emit InstantWithdraw(msg.sender, tokenAddress, amount);
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function getTokenBalance(address recipient, address tokenAddress)
        external
        view
        returns (uint256 balance)
    {
        balance = userToTokens[recipient][tokenAddress];
    }

    function createNativeTokenTransfer(
        string calldata id,
        Types.Payment[] memory payments
    ) external payable {
        require(payments.length > 0, 'no any payments');

        uint256 totalDeposit;
        for (uint256 i = 0; i < payments.length; i++) {
            address recipient = payments[i].recipient;
            require(
                recipient != address(0x00),
                'cannot send to the zero address'
            );
            require(
                recipient != address(this),
                'cannot send to the contract itself'
            );
            require(
                recipient != msg.sender,
                'cannot send to the caller address'
            );

            uint256 deposit = payments[i].deposit;
            require(deposit > 0, 'deposit is zero');

            totalDeposit += deposit;
            userToNative[recipient] += deposit;
        }
        require(totalDeposit == msg.value, 'not enough balance passed');

        emit NativeInstantTransfer(id, msg.sender, msg.value);
    }

    function withdrawNativeInstant(uint256 amount) external nonReentrant {
        require(amount > 0, 'amount is zero');
        uint256 balance = userToNative[msg.sender];
        require(balance >= amount, 'amount exceeds the available balance');
        unchecked {
            userToNative[msg.sender] = balance - amount;
        }
        (bool success, ) = msg.sender.call{value: amount}('');
        require(success, 'Transfer failed.');
        emit NativeInstantWithdraw(msg.sender, amount);
    }

    function getNativeBalance(address recipient)
        external
        view
        returns (uint256 balance)
    {
        balance = userToNative[recipient];
    }

    function payNiural(
        string calldata id,
        address tokenAddress,
        uint256 amount
    ) public {
        require(amount > 0, 'amount is zero');
        emit PayNiural(id, msg.sender, tokenAddress, amount);
        IERC20(tokenAddress).safeTransferFrom(msg.sender, owner(), amount);
    }

    function pay(
        string calldata id,
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public {
        require(amount > 0, 'amount is zero');
        require(recipient != address(0x00), 'cannot send to the zero address');
        require(recipient != msg.sender, 'cannot send to the caller address');
        emit Pay(id, msg.sender, tokenAddress, recipient, amount);
        IERC20(tokenAddress).safeTransferFrom(msg.sender, recipient, amount);
    }
}