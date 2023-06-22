// AbsoluteLabsAirdrop v0.1
// Contract performing airdrops for customers of absolutelabs.io

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./utils/Errors.sol";

contract AbsoluteLabsAirDropERC20 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // ERC20 balances per team.
    // teamId => (token contract address => balance in airdrop contract)
    mapping(string => mapping(IERC20Upgradeable => uint256))
        public erc20Balances;

    function initialize() public initializer {
        __Ownable_init();
    }

    // Provide ERC20 tokens for a given team.
    // Requires sender to have approved this contract to spend its tokens.
    function fundERC20(
        string calldata teamId,
        IERC20Upgradeable token,
        uint256 quantity
    ) external nonReentrant {
        if (token.allowance(msg.sender, address(this)) < quantity)
            revert Errors.InsufficientAllowance();
        if (token.balanceOf(msg.sender) < quantity)
            revert Errors.InsufficientBalanceToFund();
        token.transferFrom(msg.sender, address(this), quantity);
        erc20Balances[teamId][token] += quantity;
    }

    // Withdraw tokens from a team's balance.
    function withdrawERC20(
        string calldata teamId,
        IERC20Upgradeable token,
        uint256 quantity,
        address to
    ) external onlyOwner {
        if (token.balanceOf(address(this)) < quantity)
            revert Errors.InsufficientBalanceToWithdraw();
        if (erc20Balances[teamId][token] < quantity)
            revert Errors.InsufficientBalanceToWithdraw();
        token.transferFrom(address(this), to, quantity);
        erc20Balances[teamId][token] -= quantity;
    }

    // Send tokens from a team's balance to a list of recipients.
    function airdropERC20(
        string calldata teamId,
        IERC20Upgradeable token,
        address[] memory recipients,
        uint256 amountPerRecipient
    ) external onlyOwner returns (bool) {
        uint256 totalSize = amountPerRecipient * recipients.length;
        if (erc20Balances[teamId][token] < totalSize)
            revert Errors.InsufficientBalance();
        erc20Balances[teamId][token] -= totalSize;
        for (uint256 i = 0; i < recipients.length; ) {
            token.transfer(recipients[i], amountPerRecipient);

            unchecked {
                ++i;
            }
        }

        return true;
    }
}