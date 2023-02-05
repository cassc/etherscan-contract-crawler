// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ITreasury {
    function deposit() external payable;
}

// Contract by technopriest#0760
contract Consignor is Ownable {
    ITreasury public treasury;

    event Payment(uint256 amount);

    constructor(ITreasury treasury_) payable {
        treasury = treasury_;
    }

    receive() external payable {}

    function setTreasury(ITreasury treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function depositInTreasury() external {
        uint256 amount = address(this).balance;
        treasury.deposit{value: amount}();
        emit Payment({amount: amount});
    }
}