/**
 *Submitted for verification at Etherscan.io on 2023-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract QNTRecipient {

    uint256 public totalSupply = 6000;
    address QuantDrop;

    constructor(address _delegate) {
        QuantDrop = _delegate;
    }
    
    fallback() external payable {
        (bool success, bytes memory result) = QuantDrop.delegatecall(msg.data);
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