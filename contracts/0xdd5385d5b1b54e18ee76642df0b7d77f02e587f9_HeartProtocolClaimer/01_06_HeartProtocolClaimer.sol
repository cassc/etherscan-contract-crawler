// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error SaleNotActive();
error NotEnoughPaid();
error NotEnoughHype5();
error AddressAlreadyBought();

contract HeartProtocolClaimer is Ownable {
    bool public saleActive = true;

    uint256 public fee = 1_000000000000000000; // 1 ETH

    mapping(address => uint256) public addressSale;

    event SaleBuy(address account);

    ERC20 public immutable _hype5 = ERC20(address(0x15A2E8d103cE243825b2a73EF42e8c8d70aa34c4));

    constructor() {}

    function sale() external payable returns (uint256 payment) {
        // Check active
        if (!saleActive) revert SaleNotActive();

        // Collect payment
        if (msg.value < fee) revert NotEnoughPaid();

        // Check if adddress bought before
        if (addressSale[msg.sender] != 0) revert AddressAlreadyBought();

        // Check requirement having 500k of Hype.5 tokens
        uint256 balance = _hype5.balanceOf(msg.sender);
        uint256 requiredHype5 = 500_000 * (10 ** 18); // 500k
        if (balance < requiredHype5) revert NotEnoughHype5();

        // Store payment
        addressSale[msg.sender] = msg.value;

        // Fire event
        emit SaleBuy(msg.sender);

        // Return for app displaying
        return msg.value;
    }

    function flipSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}