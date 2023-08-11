// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapForBtc is ReentrancyGuard, Ownable {
    uint256 private poolBalance;

    constructor() {}

    function depositFund(uint256 _amount) external payable onlyOwner {
        require(
            (msg.value > 0 && msg.value == _amount),
            "The deposit amount must not be 0"
        );

        poolBalance += _amount;
    }

    function withdrawFund(uint256 _amount) external nonReentrant onlyOwner {
        require(address(this).balance >= _amount, "Insufficient Pool Balance");

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success);

        poolBalance -= _amount;
    }

    function getPoolBalance() public view returns (uint256) {
        return poolBalance;
    }

    function releaseFunds(
        uint256 _amount,
        address _receiver
    ) external nonReentrant onlyOwner {
        require(address(this).balance >= _amount, "Insufficient Pool Balance");

        (bool success, ) = _receiver.call{value: _amount}("");
        require(success);

        poolBalance -= _amount;

        emit EtherReleased(_amount, _receiver);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        poolBalance += msg.value;

        emit EtherDepositedForBtc(msg.value, msg.sender);
    }

    event EtherDepositedForBtc(uint256 amount, address indexed trader);
    event EtherReleased(uint256 amount, address indexed receiver);
}