// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract ERC2771Recipient is BaseRelayRecipient {
    function versionRecipient() external pure override returns (string memory) {
        return "0.1.0";
    }
}