// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// Diamond imports
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { IDiamondCut } from "../diamond/interfaces/IDiamondCut.sol";

/**************************************

    Fundraising diamond

 **************************************/

contract FundraisingDiamond {

    /**************************************

        Constructor

     **************************************/

    constructor(address _diamondCutFacet) payable {

        // owner
        address _owner = msg.sender;

        // setup ownership
        LibDiamond.setContractOwner(_owner);

        // add diamond cut facet
        LibDiamond.diamondCut(_getFirstCut(_diamondCutFacet), address(0), "");

    }

    /**************************************

        First cut

     **************************************/

    function _getFirstCut(address _diamondCutFacet) internal pure 
    returns (IDiamondCut.FacetCut[] memory) {

        // cut array
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        // selector array
        bytes4[] memory functionSelectors = new bytes4[](1);

        // selector with cut opp
        functionSelectors[0] = IDiamondCut.diamondCut.selector;

        // first cut with cut selector
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // return
        return cut;

    }

    /**************************************

        Fallback

     **************************************/

    fallback() external payable {

        // set slot position
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // get facet address
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        // delegatecall
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

    /**************************************

        Receive

     **************************************/

    receive() external payable {

        // revert sending ETH without data
        revert("Please use invest() function and specify actual raise");

    }

}