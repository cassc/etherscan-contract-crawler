// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165 } from "./@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC721 } from "./@openzeppelin/contracts/interfaces/IERC721.sol";
import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

contract Diamond {    

    constructor(address _contractOwner, address _diamondCutFacet) payable {        
        LibDiamond.flipContractOwnerStatus(_contractOwner);

		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		ds.supportedInterfaces[type(IERC721).interfaceId] = true;

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        
		bytes4[] memory diamondCutFunctionSelectors = new bytes4[](1);
        diamondCutFunctionSelectors[0] = IDiamondCut.diamondCut.selector;
		cuts[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet, 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: diamondCutFunctionSelectors
        });

        LibDiamond.diamondCut(cuts, address(0), "");        
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
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

    receive() external payable {}
}