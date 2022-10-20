// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {LivelyDiamond} from "./LivelyDiamond.sol";

/// @custom:security-contact [email protected]
contract Arise is LivelyDiamond {
    constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
        LivelyDiamond.DiamondArgs memory _args
    ) payable LivelyDiamond(_diamondCut, _args) {}
}