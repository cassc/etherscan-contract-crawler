// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// Manage payables

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981, ReentrancyGuard {
    address private constant ADDR1 = 0xa9f14b1542C9B5ace7596aC25Ade6fae82d9dDa2;
    address private constant ADDR2 = 0x4c54b734471EF8080C5c252e5588F625D2e5E93E;
    address private constant ADDR3 = 0x8bffc7415B1F8ceA3BF9e1f36EBb2FF15d175CF5;
    address private constant ADDR4 = 0x5A74eC34857BEC78E79F22a4F4F66E6A53126750;

    constructor() {
        _setRoyalties(ADDR1, 690); // 6.9% royalties
    }

    /**
     * Set the royalties information
     * @param recipient recipient of the royalties
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(recipient != address(0), "zero address");
        _setRoyalties(recipient, value);
    }

    /**
     * Withdraw funds
     */
    function withdraw() external nonReentrant {
        require(msg.sender == owner(), "Payable: Locked withdraw");
        uint256 bal = address(this).balance;
        Address.sendValue(payable(ADDR4), bal / 20); // 5
        Address.sendValue(payable(ADDR3), bal / 8); // 12.5
        Address.sendValue(payable(ADDR2), bal / 10); // 10
        Address.sendValue(payable(ADDR1), address(this).balance); // The rest
    }
}