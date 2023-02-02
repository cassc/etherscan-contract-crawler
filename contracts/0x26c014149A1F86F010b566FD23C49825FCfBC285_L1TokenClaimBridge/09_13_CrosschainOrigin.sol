// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Reference: https://github.com/ethereum-optimism/optimism-tutorial/blob/main/cross-dom-comm/contracts/Greeter.sol

import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

library CrosschainOrigin {
    function crossDomainMessenger() internal view returns (address cdmAddr) {
        // Get the cross domain messenger's address each time.
        // This is less resource intensive than writing to storage.

        if (block.chainid == 1)
            cdmAddr = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

        // Goerli
        if (block.chainid == 5)
            cdmAddr = 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;

        // Kovan
        if (block.chainid == 42)
            cdmAddr = 0x4361d0F75A0186C05f971c566dC6bEa5957483fD;

        // L2
        if (block.chainid == 10 || block.chainid == 420 || block.chainid == 69)
            cdmAddr = 0x4200000000000000000000000000000000000007;

        // Local L1 (pre-Bedrock)
        if (block.chainid == 31337) {
            cdmAddr = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
        }

        // Local L1 (Bedrock)
        if (block.chainid == 900) {
            cdmAddr = 0x6900000000000000000000000000000000000002;
        }

        // Local L2 (pre-Bedrock)
        if (block.chainid == 987) {
            cdmAddr = 0x4200000000000000000000000000000000000007;
        }

        // Local L2 (Bedrock)
        if (block.chainid == 901) {
            cdmAddr = 0x4200000000000000000000000000000000000007;
        }
    }

    function getCrosschainMessageSender() internal view returns (address) {
        // Get the cross domain messenger's address each time.
        // This is less resource intensive than writing to storage.
        address cdmAddr = crossDomainMessenger();

        // If this isn't a cross domain message
        if (msg.sender != cdmAddr) {
            revert("Not crosschain call");
        }

        // If it is a cross domain message, find out where it is from
        return ICrossDomainMessenger(cdmAddr).xDomainMessageSender();
    }
}