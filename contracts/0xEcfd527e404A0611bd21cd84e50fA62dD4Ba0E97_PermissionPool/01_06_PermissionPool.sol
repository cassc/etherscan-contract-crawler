//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PermissionPool is Ownable {
    using SafeERC20 for IERC20;

    /// @notice ERC-20 token used as currency in this pool
    IERC20 public currency;

    /// @notice Borrower in this pool
    address public borrower;

    /// @notice Lender in this pool
    address public lender;

    // EVENTS

    /// @notice Event emitted when lender lends funds to borrower
    event Lended(
        address indexed lender,
        address indexed borrower,
        uint256 amount
    );

    /// @notice Event emitted when borrower repays funds to lender
    event Repaid(
        address indexed borrower,
        address indexed lender,
        uint256 amount
    );

    // CONSTRUCTOR

    /// @notice Contract constructor
    /// @param currency_ Currency contract address
    /// @param borrower_ Borrower's address
    /// @param lender_ Lender's address
    constructor(
        IERC20 currency_,
        address borrower_,
        address lender_
    ) {
        currency = currency_;
        borrower = borrower_;
        lender = lender_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Function for lender to send funds to borrower
    /// @param amount Amount to send
    function lend(uint256 amount) external onlyLender {
        currency.safeTransferFrom(msg.sender, borrower, amount);
        emit Lended(msg.sender, borrower, amount);
    }

    /// @notice Function for borrower to send funds to lender
    /// @param amount Amount to send
    function repay(uint256 amount) external onlyBorrower {
        currency.safeTransferFrom(msg.sender, lender, amount);
        emit Repaid(msg.sender, lender, amount);
    }

    // RESTRICTED FUNCTIONS

    /// @notice Function for owner to set new borrower
    /// @param borrower_ New borrower address
    function setBorrower(address borrower_) external onlyOwner {
        borrower = borrower_;
    }

    /// @notice Function for owner to set new lender
    /// @param lender_ New lender address
    function setLender(address lender_) external onlyOwner {
        lender = lender_;
    }

    // MODIFIERS

    /// @notice Modifier that restricts function only to borrower
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Sender is not borrower");
        _;
    }

    /// @notice Modifier that restricts function only to lender
    modifier onlyLender() {
        require(msg.sender == lender, "Sender is not lender");
        _;
    }
}