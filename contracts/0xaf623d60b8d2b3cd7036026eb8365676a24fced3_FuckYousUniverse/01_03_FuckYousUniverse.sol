// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import { DiamondLib } from "./lib/DiamondLib.sol";
import { IDiamondCut } from "./lib/interfaces/IDiamondCut.sol";

// The Diamond contract

contract FuckYousUniverse {    

	constructor(address _contractOwner, address _diamondCutFacet) payable {        
		DiamondLib.setContractOwner(_contractOwner);

		// Add the diamondCut external function from the diamondCutFacet
		IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
		bytes4[] memory functionSelectors = new bytes4[](1);
		functionSelectors[0] = IDiamondCut.diamondCut.selector;
		cut[0] = IDiamondCut.FacetCut({
			facetAddress: _diamondCutFacet, 
			action: IDiamondCut.FacetCutAction.Add, 
			functionSelectors: functionSelectors
		});
		DiamondLib.diamondCut(cut, address(0), "");        
	}

	// Find facet for function that is called and execute the
	// function if a facet is found and return any value.
	fallback() external payable {
		DiamondLib.DiamondStorage storage ds;
		bytes32 position = DiamondLib.DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
		address facet = address(bytes20(ds.facets[msg.sig]));
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

	receive() external payable {}
}