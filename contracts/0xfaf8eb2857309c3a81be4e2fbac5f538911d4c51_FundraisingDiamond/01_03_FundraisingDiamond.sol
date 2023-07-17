// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// Diamond imports
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { IDiamondCut } from "../diamond/interfaces/IDiamondCut.sol";

/**************************************

    Fundraising diamond

 **************************************/

/// @notice Main fundraising diamond that delegate calls to its facets.
contract FundraisingDiamond {
    // -----------------------------------------------------------------------
    //                              Setup
    // -----------------------------------------------------------------------

    /// @dev Constructor of diamond.
    /// @dev Performs diamond cut to add diamond cut functionality to main diamond.
    /// @param _diamondCutFacet Address of diamond cut facet
    constructor(address _diamondCutFacet) payable {
        // owner
        address owner_ = msg.sender;

        // setup ownership
        LibDiamond.setContractOwner(owner_);

        // add diamond cut facet
        LibDiamond.diamondCut(_getFirstCut(_diamondCutFacet), address(0), "");
    }

    /// -----------------------------------------------------------------------
    //                              Internal
    // -----------------------------------------------------------------------

    /// @dev Builds and returns first diamond cut.
    /// @param _diamondCutFacet Address of diamond cut facet
    /// @return List of diamond cuts to perform (in this case only diamond cut from diamond cut facet is returned)
    function _getFirstCut(address _diamondCutFacet) internal pure returns (IDiamondCut.FacetCut[] memory) {
        // cut array
        IDiamondCut.FacetCut[] memory cut_ = new IDiamondCut.FacetCut[](1);

        // selector array
        bytes4[] memory functionSelectors_ = new bytes4[](1);

        // selector with cut opp
        functionSelectors_[0] = IDiamondCut.diamondCut.selector;

        // first cut with cut selector
        cut_[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors_
        });

        // return
        return cut_;
    }

    // -----------------------------------------------------------------------
    //                              Delegate call
    // -----------------------------------------------------------------------

    /**************************************

        Fallback

     **************************************/

    /// @dev Delegate call through particular facet on fallback.
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

    /// @dev Revert on receive. Contract does not accept Ether without function signature.
    receive() external payable {
        // revert sending ETH without data
        revert("Please use invest() function and specify actual raise");
    }
}