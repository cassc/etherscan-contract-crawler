// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";

contract OwnershipFacet is IOwnable {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}