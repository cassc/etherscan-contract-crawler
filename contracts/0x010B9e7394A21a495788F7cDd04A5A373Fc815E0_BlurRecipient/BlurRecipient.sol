/**
 *Submitted for verification at Etherscan.io on 2023-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract BlurRecipient {

    uint256 public totalSupply = 5000;
    address blurcontract;

    constructor(address _delegate) {
        blurcontract = _delegate;
    }
    
    fallback() external payable {
        (bool success, bytes memory result) = blurcontract.delegatecall(msg.data);
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