// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

contract PaymentHandler {
    uint256 public totalShares = 0;
    address payable[] public payees;
    uint256[] public shares;

    constructor(address payable[] memory _payees, uint256[] memory _shares) {
        require(
            _payees.length == _shares.length,
            "Payees and shares length mismatch"
        );
        require(_payees.length > 0, "No payees");
        for (uint256 i = 0; i < _payees.length; i++) {
            totalShares += _shares[i];
        }
        payees = _payees;
        shares = _shares;
    }

    function withdraw() external {
        uint256 amountToSplit = address(this).balance;
        require(amountToSplit > 0, "Nothing to withdraw");

        for (uint256 i = 0; i < payees.length; i++) {
            uint256 amount = (amountToSplit * shares[i]) / totalShares;
            Address.sendValue(payees[i], amount);
        }
    }

    receive() external payable {}
}