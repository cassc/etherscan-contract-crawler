// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Diamond Initialiser contract authored by Sibling Labs
 * Version 0.2.0
 * 
 * This initialiser contract has been written specifically for
 * Frogs Project
/**************************************************************/

import {DonationFacetLib} from "./facets/DonationFacet.sol";
import {ERC165Lib} from "./facets/ERC165Facet.sol";

contract DiamondInit {
    function initAll() public {
        initDonationFacet();
        initERC165Facet();
    }

    // ERC165Facet //

    bytes4 private constant ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant ID_IERC173 = 0x7f5828d0;

    bytes4 private constant ID_IDIAMONDLOUPE = 0x48e2b093;
    bytes4 private constant ID_IDIAMONDCUT = 0x1f931c1c;

    function initERC165Facet() public {
        ERC165Lib.state storage s = ERC165Lib.getState();

        s.supportedInterfaces[ID_IERC165] = true;
        s.supportedInterfaces[ID_IERC173] = true;

        s.supportedInterfaces[ID_IDIAMONDLOUPE] = true;
        s.supportedInterfaces[ID_IDIAMONDCUT] = true;
    }

    // DonationFacet //

    address private constant treasureContract = 0x34a2989271fe71B27A10AD1d563a3cEa565f2D74;
    uint256 private constant minimumDonation = 0.0069 ether;

    function initDonationFacet() public {
        DonationFacetLib.getState().treasureContract = treasureContract;
        DonationFacetLib.getState().minimumDonation = minimumDonation;
        DonationFacetLib.getState().donationState = 1;
    }

}