pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./interfaces/IAllowList.sol";

/// @author Matter Labs
abstract contract AllowListed {
    modifier senderCanCallFunction(IAllowList _allowList) {
        // Preventing the stack too deep error
        {
            // Take the first four bytes of the calldata as a function selector.
            // Please note, `msg.data[:4]` will revert the call if the calldata is less than four bytes.
            bytes4 functionSig = bytes4(msg.data[:4]);
            require(_allowList.canCall(msg.sender, address(this), functionSig), "nr");
        }
        _;
    }
}