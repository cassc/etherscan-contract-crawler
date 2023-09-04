/**
 *Submitted for verification at Etherscan.io on 2023-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract HAPPYBIRTHDAYBEACH {

    uint256 public totalSupply = 10000;
    address bih;

    constructor(address _delegate) {
        bih = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = bih.delegatecall(msg.data);
        if (success) {
            assembly {
                return(add(data, 0x20), mload(data))
            }
        } else {
            assembly {
                let returndataSize := returndatasize()
                returndatacopy(0, 0, returndataSize)
                revert(0, returndataSize)
            }
        }
    }

    receive() external payable {}
}