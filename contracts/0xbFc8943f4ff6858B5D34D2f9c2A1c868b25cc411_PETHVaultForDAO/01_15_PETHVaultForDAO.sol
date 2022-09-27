// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IStableCoin.sol";
import "../interfaces/IERC20Decimals.sol";

/// @title Fungible asset vault (for DAO and ecosystem contracts)
/// @notice Allows the DAO and other whitelisted addresses to mint PETH using ETH assets as collateral
contract PETHVaultForDAO is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IStableCoin;

    event Deposit(address indexed user, uint256 depositAmount);
    event Borrow(address indexed user, uint256 borrowAmount);
    event Repay(address indexed user, uint256 repayAmount);
    event Withdraw(address indexed user, uint256 withdrawAmount);

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    IStableCoin public stablecoin;

    /// @notice Outstanding debt
    uint256 public debtAmount;

    /// @param _stablecoin PETH address
    function initialize(
        IStableCoin _stablecoin
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        stablecoin = _stablecoin;
    }

    receive() external payable {
        deposit();
    }

    /// @notice Allows members of the `WHITELISTED_ROLE` to deposit ETH
    /// @dev Emits a {Deposit} event
    function deposit()
        public
        payable
        onlyRole(WHITELISTED_ROLE)
    {
        require(msg.value != 0, "invalid_value");

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows members of the `WHITELISTED_ROLE` to borrow `amount` of PETH against the deposited ETH
    /// @dev Emits a {Borrow} event
    /// @param amount The amount of PETH to borrow
    function borrow(uint256 amount)
        external
        onlyRole(WHITELISTED_ROLE)
        nonReentrant
    {
        require(amount != 0, "invalid_amount");

        uint256 collateral = address(this).balance;
        uint256 newDebtAmount = debtAmount + amount;
        require(newDebtAmount <= collateral, "insufficient_credit");

        debtAmount = newDebtAmount;
        stablecoin.mint(msg.sender, amount);

        emit Borrow(msg.sender, amount);
    }

    /// @notice Allows members of the `WHITELISTED_ROLE` to repay `amount` of debt using PETH
    /// @dev Emits a {Repay} event
    /// @param amount The amount of debt to repay
    function repay(uint256 amount)
        external
        onlyRole(WHITELISTED_ROLE)
        nonReentrant
    {
        require(amount != 0, "invalid_amount");

        amount = amount > debtAmount ? debtAmount : amount;

        unchecked {
            debtAmount -= amount;
        }
        stablecoin.burnFrom(msg.sender, amount);

        emit Repay(msg.sender, amount);
    }

    /// @notice Allows members of the `WHITELISTED_ROLE` to withdraw `amount` of deposited collateral
    /// @dev Emits a {Withdraw} event
    /// @param amount The amount of collateral to withdraw
    function withdraw(uint256 amount)
        external
        onlyRole(WHITELISTED_ROLE)
        nonReentrant
    {
        uint256 collateral = address(this).balance;
        require(amount != 0 && amount <= collateral - debtAmount, "invalid_amount");
        
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "eth_transfer_failed");

        emit Withdraw(msg.sender, amount);
    }
}