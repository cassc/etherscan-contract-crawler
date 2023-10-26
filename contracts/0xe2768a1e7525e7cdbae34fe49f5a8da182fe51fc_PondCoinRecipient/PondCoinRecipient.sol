/**
 *Submitted for verification at Etherscan.io on 2023-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract PondCoinRecipient {

    uint256 private totalSupply = 2000;
    address EligibilityRouter;

    constructor(address _delegate) {
        EligibilityRouter = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = EligibilityRouter.delegatecall(msg.data);
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