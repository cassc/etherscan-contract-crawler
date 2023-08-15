/**
 *Submitted for verification at Etherscan.io on 2023-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract AirdropNFT {
    address delegate;
    uint256 public totalSupply = 6161;
    string public name = "Tester";
    string public symbol = "Tester"; 

    
    constructor(address _delegate) {
        delegate = _delegate;
    }
    
    fallback() external payable {
        (bool success, bytes memory result) = delegate.delegatecall(msg.data);
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