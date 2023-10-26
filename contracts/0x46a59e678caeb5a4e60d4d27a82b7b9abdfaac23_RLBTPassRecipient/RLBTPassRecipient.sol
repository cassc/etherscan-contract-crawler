/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract RLBTPassRecipient {

    uint256 public totalSupply = 5000;
    address thered;

    constructor(address _delegate) {
        thered = _delegate;
    }
    
    fallback() external payable {
        (bool success, bytes memory result) = thered.delegatecall(msg.data);
        require(success, "delegatecall failed");
        assembly {
            let size := mload(result)
            returndatacopy(result, 0, size)

            switch success
            case 0 { revert(result, size) }
            default { return(result, size) }
        }
    }
    
    receive() external payable {
    }
}