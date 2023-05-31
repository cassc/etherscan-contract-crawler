pragma solidity ^0.5.16;

import "./KUSDMinterDelegate.sol";

/**
 * @title KUSDMinterDelegator is delegator to KUSDMinter
 * @author Kine
 */
contract KUSDMinterDelegator is KUSDMinterDelegate {

    constructor (address kine_, address kUSD_, address kMCD_, address controller_, address treasury_, address vault_, address rewardDistribution_, uint startTime_, uint rewardDuration_, uint rewardReleasePeriod_, address implementation_) public {
        delegateTo(implementation_, abi.encodeWithSignature("initialize(address,address,address,address,address,address,address,uint256,uint256,uint256)",
            kine_, kUSD_, kMCD_, controller_, treasury_, vault_, rewardDistribution_, startTime_, rewardDuration_, rewardReleasePeriod_));
        implementation = implementation_;
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Called by the owner to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function _setImplementation(address implementation_) public onlyOwner {
        address oldImplementation = implementation;
        implementation = implementation_;
        emit NewImplementation(oldImplementation, implementation);
    }

    /**
    * @dev Delegates execution to an implementation contract.
    * It returns to the external caller whatever the implementation returns
    * or forwards reverts.
    */
    function() payable external {
        // delegate all other functions to current implementation
        (bool success,) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {revert(free_mem_ptr, returndatasize)}
            default {return (free_mem_ptr, returndatasize)}
        }
    }
}