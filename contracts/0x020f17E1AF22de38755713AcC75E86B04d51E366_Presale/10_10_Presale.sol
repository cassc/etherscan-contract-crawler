// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Presale is Ownable, Pausable, ReentrancyGuard {
    IERC20 public token;
    uint256 private constant PRE_SALE_AMOUNT = 20 * 10 ** 9 * 10 ** 18; // 20 Billion tokens, assumes 18 decimal places
    uint256 private constant DEPOSIT_AMOUNT = 5 * 10 ** 16; // 0.05 ETH
    bool public depositOpen;
    bool public claimOpen;

    // This is a mapping to keep track of who claimed tokens.
    mapping(address => bool) public claimed;

    // This is a mapping to keep track of who deposited ETH.
    mapping(address => bool) public deposited;

    constructor(IERC20 _token) {
        token = _token;
        depositOpen = true;
        claimOpen = false;
    }

    function deposit() public payable whenNotPaused nonReentrant {
        require(depositOpen, "Deposit phase closed");
        require(msg.value == DEPOSIT_AMOUNT, "Incorrect value sent");
        require(!deposited[msg.sender], "Already deposited");

        // Register the sender as having deposited
        deposited[msg.sender] = true;
    }

    function claim() external whenNotPaused nonReentrant {
        require(claimOpen, "Claim phase not open yet");
        require(deposited[msg.sender], "Nothing to claim");
        require(!claimed[msg.sender], "Already claimed");
        require(
            token.balanceOf(address(this)) >= PRE_SALE_AMOUNT,
            "Not enough tokens to distribute"
        );

        // Mark it claimed and send the token.
        claimed[msg.sender] = true;
        require(
            token.transfer(msg.sender, PRE_SALE_AMOUNT),
            "Transfer failed."
        );
    }

    function setClaimOpen(bool _isOpen) external onlyOwner {
        claimOpen = _isOpen;
    }

    function setDepositOpen(bool _isOpen) external onlyOwner {
        depositOpen = _isOpen;
    }

    function setToken(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Invalid token address");
        token = _token;
    }

    function withdraw() external onlyOwner {
        // Withdraw the contract balance to the owner
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(token.transfer(owner(), balance), "Transfer failed.");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}