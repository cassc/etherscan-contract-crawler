// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibDiamond} from "../../libraries/diamond/standard/LibDiamond.sol";

abstract contract BFacetOwner {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}