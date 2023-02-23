pragma solidity 0.6.12;
// SPDX-License-Identifier: MIT

import "./ownable.sol";

// This contract is used to set a delegated contract, so that the functions of delegated contract would be callable from the main contract.
contract Proxy is ownable {
// Logic layer variable:
    address delegatedAddress;

// Sets the delegated contract address.
// This function can only send once.
    function setDelegatedAddress(address _delegatedAddress) public isOwner {
        require(delegatedAddress == address(0),"Delegated address is set before.");
        require(_delegatedAddress != address(0),"Invalid new address.");
        delegatedAddress = _delegatedAddress;
    }

// This function gets the delegated contract address.
    function getDelegatedAddress() public view returns(address) {
        return(delegatedAddress);
    }

    fallback() external {
        address target = delegatedAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}