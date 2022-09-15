// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    ///@notice Transfer ownership to new owner
    ///@param _newOwner - address nof new owner
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    ///@notice returns current contract owner
    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}