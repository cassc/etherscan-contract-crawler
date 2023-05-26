pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenDelegatorStorage, TokenEvents } from "./TokenInterfaces.sol";

contract InstaToken is TokenDelegatorStorage, TokenEvents {
    constructor(
        address account,
        address implementation_,
        uint initialSupply_,
        uint mintingAllowedAfter_,
        bool transferPaused_
    ) {
        require(implementation_ != address(0), "TokenDelegator::constructor invalid address");
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,bool)",
                account,
                initialSupply_,
                mintingAllowedAfter_,
                transferPaused_
            )
        );

        implementation = implementation_;

        emit NewImplementation(address(0), implementation);
    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function _setImplementation(address implementation_) external isMaster {
        require(implementation_ != address(0), "TokenDelegator::_setImplementation: invalid implementation address");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback () external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}