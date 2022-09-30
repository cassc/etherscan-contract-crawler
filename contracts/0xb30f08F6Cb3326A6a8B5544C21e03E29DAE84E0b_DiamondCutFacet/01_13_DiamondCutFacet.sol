// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCutFacet} from "../interfaces/IDiamondCutFacet.sol";
import {LibDiamond} from "../libs/LibDiamond.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";

contract DiamondCutFacet is IDiamondCutFacet, Modifiers {
    /// @inheritdoc IDiamondCutFacet
    function diamondCut(
        FacetCut[] calldata cut,
        address init,
        bytes calldata data
    ) external onlyDiamondController {
        LibDiamond.diamondCut(cut, init, data);
    }
}