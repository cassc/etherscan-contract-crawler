// SPDX-License-Identifier: Not Licensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * An abstract contract that provides subclasses
 * with a classical implementation of "batch transfer" functionality.
 * Although pulling (= withdrawal) is always preferrable to pushing (= transfer),
 * there are cases that latter is more convenient.
 */
abstract contract ERC20BatchTransferrableToken is ERC20 {
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        require(
            recipients.length == amounts.length,
            "BatchTransfer: number mismatch between recipients and amounts"
        );
        require(0 < recipients.length, "BatchTransfer: lists are empty");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                transfer(recipients[i], amounts[i]),
                "BatchTransfer: transfer failed"
            );
        }
        return true;
    }

    function batchTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        require(
            recipients.length == amounts.length,
            "BatchTransfer: number mismatch between recipients and amounts"
        );
        require(0 < recipients.length, "BatchTransfer: lists are empty");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                transferFrom(from, recipients[i], amounts[i]),
                "BatchTransfer: transfer failed"
            );
        }
        return true;
    }
}