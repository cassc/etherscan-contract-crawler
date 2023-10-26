// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../domain/BosonConstants.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";
import { IDiamondLoupe } from "../interfaces/diamond/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/diamond/IDiamondCut.sol";
import { DiamondLib } from "./DiamondLib.sol";
import { JewelerLib } from "./JewelerLib.sol";

/**
 * @title ProtocolDiamond
 *
 * @notice Provides Diamond functionality based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces. Also added copious code comments throughout.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract ProtocolDiamond {
    /**
     * @notice Constructor
     *
     * - Stores the access controller
     * - Makes the initial facet cuts
     * - Declares support for interfaces
     *
     * @param _accessController - the Boson Protocol AccessController
     * @param _facetCuts - the initial facet cuts to make
     * @param _interfaceIds - the initially supported ERC-165 interface ids
     */
    constructor(
        IAccessControl _accessController,
        IDiamondCut.FacetCut[] memory _facetCuts,
        bytes4[] memory _interfaceIds
    ) {
        require(address(_accessController) != address(0), INVALID_ADDRESS);

        // Get the DiamondStorage struct
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Set the AccessController instance
        ds.accessController = _accessController;

        // Cut the diamond with the given facets
        JewelerLib.diamondCut(_facetCuts, address(0), new bytes(0));

        // Add supported interfaces
        for (uint8 x = 0; x < _interfaceIds.length; x++) {
            DiamondLib.addSupportedInterface(_interfaceIds[x]);
        }
    }

    /**
     * @notice Fallback function. Is called when the specified function doesn't exist.
     *
     * Finds facet for function that is called and executes the
     * function if a facet is found and returns any value.
     */
    fallback() external payable {
        // Get the DiamondStorage struct
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Make sure the function exists
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");

        // Invoke the function with delagatecall
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

    /// Contract can receive ETH
    receive() external payable {}
}