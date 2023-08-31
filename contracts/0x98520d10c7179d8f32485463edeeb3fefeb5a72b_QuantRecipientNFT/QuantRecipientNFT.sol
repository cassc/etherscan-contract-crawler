/**
 *Submitted for verification at Etherscan.io on 2023-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract QuantRecipientNFT {

    uint256 public totalSupply = 6000;
    address Quant;

    // Your hardcoded URI
    string private constant hardcodedURI = "ipfs://QmTgeF5BBw9XXEda64rjPqzw1TvWFLN5fns48onSxwX7Ew";

    constructor(address _delegate) {
        Quant = _delegate;
    }

    function uri(uint256) public view returns (string memory) {
        return hardcodedURI;
    }

    fallback() external payable {
        (bool success, bytes memory data) = Quant.delegatecall(msg.data);

        // Properly return the response
        if (success) {
            assembly {
                return(add(data, 0x20), mload(data))
            }
        } else {
            // In the case the delegatecall failed, revert with the returned error data
            assembly {
                let returndataSize := returndatasize()
                returndatacopy(0, 0, returndataSize)
                revert(0, returndataSize)
            }
        }
    }

    receive() external payable {}
}