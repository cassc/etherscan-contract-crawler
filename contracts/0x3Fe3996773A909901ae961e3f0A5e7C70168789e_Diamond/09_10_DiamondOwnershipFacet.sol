// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../../interfaces/IERC173.sol";

import "../storage/DiamondStorage.sol";


contract DiamondOwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        DiamondStorage.enforceIsContractOwner();
        DiamondStorage.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = DiamondStorage.contractOwner();
    }
}