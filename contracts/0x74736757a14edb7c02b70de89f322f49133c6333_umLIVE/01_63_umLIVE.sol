// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {Lively1155Diamond} from "./Lively1155Diamond.sol";

/// @custom:security-contact [email protected]
contract umLIVE is Lively1155Diamond {
    constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
        Lively1155Diamond.DiamondArgs memory _args
    ) payable Lively1155Diamond(_diamondCut, _args) {}
}