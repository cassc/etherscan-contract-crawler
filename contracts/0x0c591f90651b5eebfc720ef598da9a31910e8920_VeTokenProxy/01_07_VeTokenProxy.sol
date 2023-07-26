// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VeTokenStorage.sol";
import "./AccessControl.sol";

/**
 * @title VeTokenCore
 * @dev Storage for the VeToken is at this address, while execution is delegated to the `veTokenImplementation`.
 */
contract VeTokenProxy is AccessControl, ProxyStorage {
    function setPendingImplementation(
        address newPendingImplementation_
    ) public onlyOwner 
    {
        address oldPendingImplementation = pendingVeTokenImplementation;

        pendingVeTokenImplementation = newPendingImplementation_;

        emit NewPendingImplementation(oldPendingImplementation, pendingVeTokenImplementation);
    }

    /**
    * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require (msg.sender == pendingVeTokenImplementation && pendingVeTokenImplementation != address(0),
                "Invalid veTokenImplementation");

        // Save current values for inclusion in log
        address oldImplementation = veTokenImplementation;
        address oldPendingImplementation = pendingVeTokenImplementation;

        veTokenImplementation = oldPendingImplementation;

        pendingVeTokenImplementation = address(0);

        emit NewImplementation(oldImplementation, veTokenImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingVeTokenImplementation);
    }
    
    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback () external payable {
        // delegate all other functions to current implementation
        (bool success, ) = veTokenImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

    receive () external payable {}

    function claim (address receiver) external onlyOwner nonReentrant {
        payable(receiver).transfer(address(this).balance);

        emit Claim(receiver);
    }

    /**
      * @notice Emitted when pendingComptrollerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);
   
    /**
      * @notice Emitted when claim eth in contract
      */
    event Claim(address receiver);
}