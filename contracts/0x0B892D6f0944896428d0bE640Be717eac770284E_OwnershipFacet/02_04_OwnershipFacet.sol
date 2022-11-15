// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "./LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

/// @notice Allows the diamond to transfer ownership of the diamond to another address
contract OwnershipFacet is IERC173 {

    /// @notice transfer the ownership of the diamond to another address
    /// @param _newOwner the new owner of the diamond
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /// @notice renounce the ownership of the diamond
    function renounceOwnership() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(address(0));
    }
    
    /// @notice get the owner of the diamond contract
    /// @return owner_ address of the new owner
    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

}