// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { LibDiamondCut } from "./diamond/LibDiamondCut.sol";
import { DiamondFacet } from "./diamond/DiamondFacet.sol";
import { OwnershipFacet } from "./diamond/OwnershipFacet.sol";
import { LibDiamondStorage } from "./diamond/LibDiamondStorage.sol";
import { IDiamondCut } from "./diamond/IDiamondCut.sol";
import { IDiamondLoupe } from "./diamond/IDiamondLoupe.sol";
import { IERC165 } from "./diamond/IERC165.sol";
import { LibDiamondStorageDerivaDEX } from "./storage/LibDiamondStorageDerivaDEX.sol";
import { IDDX } from "./tokens/interfaces/IDDX.sol";

/**
 * @title DerivaDEX
 * @author DerivaDEX
 * @notice This is the diamond for DerivaDEX. All current
 *         and future logic runs by way of this contract.
 * @dev This diamond implements the Diamond Standard (EIP #2535).
 */
contract DerivaDEX {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice This constructor initializes the upgrade machinery (as
     *         per the Diamond Standard), sets the admin of the proxy
     *         to be the deploying address (very temporary), and sets
     *         the native DDX governance/operational token.
     * @param _ddxToken The native DDX token address.
     */
    constructor(IDDX _ddxToken) public {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();

        // Temporarily set admin to the deploying address to facilitate
        // adding the Diamond functions
        dsDerivaDEX.admin = msg.sender;

        // Set DDX token address for token logic in facet contracts
        require(address(_ddxToken) != address(0), "DerivaDEX: ddx token is zero address.");
        dsDerivaDEX.ddxToken = _ddxToken;

        emit OwnershipTransferred(address(0), msg.sender);

        // Create DiamondFacet contract -
        // implements DiamondCut interface and DiamondLoupe interface
        DiamondFacet diamondFacet = new DiamondFacet();

        // Create OwnershipFacet contract which implements ownership
        // functions and supportsInterface function
        OwnershipFacet ownershipFacet = new OwnershipFacet();

        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](2);

        // adding diamondCut function and diamond loupe functions
        diamondCut[0].facetAddress = address(diamondFacet);
        diamondCut[0].action = IDiamondCut.FacetCutAction.Add;
        diamondCut[0].functionSelectors = new bytes4[](6);
        diamondCut[0].functionSelectors[0] = DiamondFacet.diamondCut.selector;
        diamondCut[0].functionSelectors[1] = DiamondFacet.facetFunctionSelectors.selector;
        diamondCut[0].functionSelectors[2] = DiamondFacet.facets.selector;
        diamondCut[0].functionSelectors[3] = DiamondFacet.facetAddress.selector;
        diamondCut[0].functionSelectors[4] = DiamondFacet.facetAddresses.selector;
        diamondCut[0].functionSelectors[5] = DiamondFacet.supportsInterface.selector;

        // adding ownership functions
        diamondCut[1].facetAddress = address(ownershipFacet);
        diamondCut[1].action = IDiamondCut.FacetCutAction.Add;
        diamondCut[1].functionSelectors = new bytes4[](2);
        diamondCut[1].functionSelectors[0] = OwnershipFacet.transferOwnershipToSelf.selector;
        diamondCut[1].functionSelectors[1] = OwnershipFacet.getAdmin.selector;

        // execute internal diamondCut function to add functions
        LibDiamondCut.diamondCut(diamondCut, address(0), new bytes(0));

        // adding ERC165 data
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;
        ds.supportedInterfaces[IDiamondCut.diamondCut.selector] = true;
        bytes4 interfaceID =
            IDiamondLoupe.facets.selector ^
                IDiamondLoupe.facetFunctionSelectors.selector ^
                IDiamondLoupe.facetAddresses.selector ^
                IDiamondLoupe.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;
    }

    // TODO(jalextowle): Remove this linter directive when
    // https://github.com/protofire/solhint/issues/248 is merged and released.
    /* solhint-disable ordering */
    receive() external payable {
        revert("DerivaDEX does not directly accept ether.");
    }

    // Finds facet for function that is called and executes the
    // function if it is found and returns any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds;
        bytes32 position = LibDiamondStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds_slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Function does not exist.");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
                case 0 {
                    revert(0, size)
                }
                default {
                    return(0, size)
                }
        }
    }
    /* solhint-enable ordering */
}