// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Initialiser contract authored by Sibling Labs
 * Version 0.1.0
 * 
 * This initialiser contract has been written specifically for
 * KOREAN-SANTA by Sibling Labs
/**************************************************************/

import { GlobalState } from "./libraries/GlobalState.sol";
import { ERC165Lib } from "./facets/ERC165Facet.sol";
import { TokenFacetLib, ERC1155Lib } from "./facets/TokenFacet.sol";

contract DiamondInit {

    function initAll() public {
        initAdminPrivilegesFacet();
        initERC165Facet();
        initTokenFacet();
    }

    // AdminPrivilegesFacet //

    function initAdminPrivilegesFacet() public {
        // List of admins must be placed inside this function,
        // as arrays cannot be constant and
        // therefore will not be accessible by the
        // delegatecall from the diamond contract.
        address[] memory admins = new address[](1);
        admins[0] = 0x885Af893004B4405Dc18af1A4147DCDCBdA62b50;

        for (uint256 i; i < admins.length; i++) {
            GlobalState.getState().admins[admins[i]] = true;
        }
    }

    // ERC165Facet //

    bytes4 private constant ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant ID_IERC173 = 0x7f5828d0;
    bytes4 private constant ID_IERC2981 = 0x2a55205a;
    bytes4 private constant ID_IERC721 = 0x80ac58cd;
    bytes4 private constant ID_IERC721METADATA = 0x5b5e139f;
    bytes4 private constant ID_IDIAMONDLOUPE = 0x48e2b093;
    bytes4 private constant ID_IDIAMONDCUT = 0x1f931c1c;

    function initERC165Facet() public {
        ERC165Lib.state storage s = ERC165Lib.getState();

        s.supportedInterfaces[ID_IERC165] = true;
        s.supportedInterfaces[ID_IERC173] = true;
        s.supportedInterfaces[ID_IERC2981] = true;
        s.supportedInterfaces[ID_IERC721] = true;
        s.supportedInterfaces[ID_IERC721METADATA] = true;

        s.supportedInterfaces[ID_IDIAMONDLOUPE] = true;
        s.supportedInterfaces[ID_IDIAMONDCUT] = true;
    }

    // TokenFacet //

    string private constant uri = "https://api.koreanfts.xyz";

    function initTokenFacet() public {
        ERC1155Lib.getState()._uri = uri;
    }

}