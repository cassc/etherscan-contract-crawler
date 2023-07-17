// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title A base contract that may be inherited in order to protect a contract from having its fallback function 
 * invoked and to block the receipt of ETH by a contract.
 * @author Nathan Gang
 * @notice This contract bestows on inheritors the ability to block ETH transfers into the contract
 * @dev ETH may still be forced into the contract - it is impossible to block certain attacks, but this protects from accidental ETH deposits
 */
 // For more info, see: "https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56"
abstract contract RejectEther {    

    /**
     * @dev For most contracts, it is safest to explicitly restrict the use of the fallback function
     * This would generally be invoked if sending ETH to this contract with a 'data' value provided
     */
    fallback() external payable {        
        revert("Fallback function not permitted");
    }

    /**
     * @dev This is the standard path where ETH would land if sending ETH to this contract without a 'data' value
     * In our case, we don't want our contract to receive ETH, so we restrict it here
     */
    receive() external payable {
        revert("Receiving ETH not permitted");
    }    
}