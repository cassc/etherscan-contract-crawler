//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageDominiumProxy} from "../storage/StorageDominiumProxy.sol";
import {IDiamondLoupe} from "../external/diamond/interfaces/IDiamondLoupe.sol";
import {LibDiamond} from "../external/diamond/libraries/LibDiamond.sol";

/// @author Amit Molek
/// @dev This contract is designed to forward all calls to the Dominium contract.
/// Please take a look at the Dominium contract.
///
/// The fallback works in two steps:
///     1. Calls the DiamondLoupe to get the facet that implements the called function
///     2. Delegatecalls the facet
///
/// The first step is necessary because the DiamondLoupe stores the facets addresses
/// in storage.
contract DominiumProxy {
    constructor(address implementation) {
        StorageDominiumProxy.DiamondStorage storage ds = StorageDominiumProxy
            .diamondStorage();

        ds.implementation = implementation;
    }

    fallback() external payable {
        // get loupe from storage
        StorageDominiumProxy.DiamondStorage storage ds = StorageDominiumProxy
            .diamondStorage();

        // get facet from loupe and verify for existence
        address facet = IDiamondLoupe(ds.implementation).facetAddress(msg.sig);
        LibDiamond.enforceHasContractCode(
            facet,
            "DominiumProxy: Function does not exist"
        );

        // execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
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