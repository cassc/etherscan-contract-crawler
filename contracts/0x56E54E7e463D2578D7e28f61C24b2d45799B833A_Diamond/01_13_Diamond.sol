// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IDiamondCutFacet} from "./interfaces/IDiamondCutFacet.sol";
import {LibAppStorage} from "./libs/LibAppStorage.sol";
import {LibDiamond} from "./libs/LibDiamond.sol";

/// @title MeTokens protocol Diamond
/// @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/// @notice The meTokens protocol core proxy contract.
contract Diamond {
    constructor(address firstController, address diamondCutFacet) payable {
        LibAppStorage.initControllers(firstController);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCutFacet.FacetCut[]
            memory cut = new IDiamondCutFacet.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCutFacet.diamondCut.selector;
        cut[0] = IDiamondCutFacet.FacetCut({
            facetAddress: diamondCutFacet,
            action: IDiamondCutFacet.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    receive() external payable {}

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    /* solhint-disable */
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
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