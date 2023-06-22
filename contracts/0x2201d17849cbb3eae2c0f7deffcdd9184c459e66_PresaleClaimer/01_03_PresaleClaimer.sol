// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

error PresaleNotActive();
error NotEnoughPaid();
error TooMuchPaid();
error AddressAlreadyBought();

contract PresaleClaimer is Ownable {
    bool public presaleActive = true;

    uint256 public minimumFee = 1_00000000000000000; // 0.1 ETH
    uint256 public maximumFee = 1_000000000000000000; // 1 ETH

    mapping(address => uint256) public addressPresale;

    event PresaleBuy(address account, uint256 value);

    constructor() {}

    function presale() external payable returns (uint256 payment) {
        // Check active
        if (!presaleActive) revert PresaleNotActive();

        // Collect payment
        if (msg.value < minimumFee) revert NotEnoughPaid();
        if (msg.value > maximumFee) revert TooMuchPaid();

        // Check if adddress bought before
        if (addressPresale[msg.sender] != 0) revert AddressAlreadyBought();

        // Store payment
        addressPresale[msg.sender] = msg.value;

        // Fire event
        emit PresaleBuy(msg.sender, msg.value);

        // Return for app displaying
        return msg.value;
    }

    function flipPresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}