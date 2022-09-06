// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritable } from "./IDiamondWritable.sol";
import { DiamondWritableController } from "./DiamondWritableController.sol";

/**
 * @title Diamond write operations implementation
 */
contract DiamondWritable is IDiamondWritable, DiamondWritableController {
    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address init,
        bytes calldata data
    ) external virtual onlyOwner {
        diamondCut_(facetCuts, init, data);
    }
}