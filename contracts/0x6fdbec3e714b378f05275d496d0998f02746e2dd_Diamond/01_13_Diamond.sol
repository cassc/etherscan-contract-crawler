// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/******************************************************************************\
* Authors: Nick Mudge (https://twitter.com/mudgen)
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";
import {AccessControl} from "./libraries/LibAccessControl.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet, address _diamondLoupeFacet, address _ownershipFacet) {
        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.addDiamondFunctions(_diamondCutFacet, _diamondLoupeFacet, _ownershipFacet);
        AccessControl.initialize(_contractOwner);
    }

    receive() external payable {}

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        bytes32[] memory roles = ds.selectorToAccessControl[msg.sig];
        bool isAuthorized = roles.length == 0;
        for (uint256 i = 0; i < roles.length; i++) {
            if(AccessControl.hasRole(roles[i], msg.sender)) {
                isAuthorized = true;
                break;
            }
        }
        require(isAuthorized, "RBAC: unauthorized");
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}