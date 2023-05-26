// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenSwap is Ownable, Pausable, ReentrancyGuard {
    // Global Variables
    ERC20 public TOKEN;
    uint256 public RATE = 11520000000;
    uint256 MINDEPOSIT = (1 / 1000) * 1 ether;
    uint256 MAXDEPOSIT = 1 ether;

    // Events
    event TokenSwapped(
        address indexed User,
        uint256 indexed AmountReceived,
        uint256 indexed AmountSent,
        address ReceivedToken
    );

    // Constructor
    constructor(address _token) {
        require(_token != address(0), "Cannot set zero address");
        TOKEN = ERC20(_token);
        _pause();
    }

    receive() external payable whenNotPaused nonReentrant {
        require(msg.value >= MINDEPOSIT, "Amount too small");
        require(msg.value <= MAXDEPOSIT, "Amount too high");

        (
            uint256 amountToReceive,
            uint256 EthToRefund
        ) = _calculateAmountReceived(msg.value);

        if (EthToRefund > 0) {
            (bool sent, bytes memory data) = msg.sender.call{
                value: EthToRefund
            }("");
            require(sent, "Failed to send Ether");
        }

        // Transfer ETH sent to contract to owner

        (bool sent, bytes memory data) = owner().call{value: msg.value}("");

        // Transfer TOKEN from contract to user

        TOKEN.transfer(msg.sender, amountToReceive);

        emit TokenSwapped(msg.sender, amountToReceive, msg.value, address(TOKEN));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Swap USDT for TOKEN

    function swapETHForToken() public payable whenNotPaused nonReentrant {
        require(msg.value >= MINDEPOSIT, "Amount too small");
        require(msg.value <= MAXDEPOSIT, "Amount too much");

        (
            uint256 amountToReceive,
            uint256 EthToRefund
        ) = _calculateAmountReceived(msg.value);

        if (EthToRefund > 0) {
            (bool sent, bytes memory data) = msg.sender.call{
                value: EthToRefund
            }("");
            require(sent, "Failed to send Ether");
        }

        // Transfer ETH sent to contract to owner

        (bool sent, bytes memory data) = owner().call{value: msg.value}("");

        // Transfer TOKEN from contract to user

        TOKEN.transfer(msg.sender, amountToReceive);

        emit TokenSwapped(msg.sender, amountToReceive, msg.value, address(TOKEN));
    }

    // Withdraw any ERC20 token from contract

    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Cannot withdraw zero address token");
        require(_amount > 0, "Cannot withdraw zero amount");
        require(
            _token != address(TOKEN),
            "Cannot withdraw TOKEN from contract"
        );
        ERC20(_token).transfer(msg.sender, _amount);
    }

    // Get ETH balance of contract

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Get TOKEN balance of contract

    function getTokenBalance() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    // Withdraw TOKEN from contract

    function withdrawTOKEN(uint256 _amount) external onlyOwner {
        require(
            TOKEN.balanceOf(address(this)) >= _amount,
            "Not enough TOKEN in contract"
        );
        TOKEN.transfer(msg.sender, _amount);
    }

    // Get rates

    function _getRates() internal view returns (uint256) {
        return RATE;
    }

    // Set rates

    function setRates(uint256 _rate) external onlyOwner {
        RATE = _rate;
    }

    // Calculate amount of TOKEN to be received

    function _calculateAmountReceived(
        uint256 _amount
    ) internal view returns (uint256 amountToReceive, uint256 EthToRefund) {
        uint256 tokenBalance = getTokenBalance();
        require(tokenBalance > 0, "Contract doesn't have suffient funds");

         amountToReceive = _amount * RATE;

        if (amountToReceive > tokenBalance) {
            unchecked {
                EthToRefund = _amount - (tokenBalance / RATE);
            }

            amountToReceive = tokenBalance;

            return (amountToReceive, EthToRefund);
        }

        return (amountToReceive, 0);
    }
}