// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Fund {
    function fund(address[] calldata recipients, uint256[] calldata amounts) external payable {
        unchecked {
            for (uint256 i; i < recipients.length; i++) recipients[i].call{value: amounts[i]}('');
            if (address(this).balance > 0) msg.sender.call{value: address(this).balance}('');
        }
    }
}