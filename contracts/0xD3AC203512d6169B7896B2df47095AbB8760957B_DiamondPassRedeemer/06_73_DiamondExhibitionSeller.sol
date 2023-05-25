// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {SellableCallbacker} from "proof/sellers/base/SellableCallbacker.sol";
import {Seller} from "proof/sellers/base/Seller.sol";

import {DiamondExhibitionLib, DiamondExhibition} from "../exhibition/DiamondExhibition.sol";

/**
 * @notice Seller module to purchase Diamond Exhibition tokens.
 */
abstract contract DiamondExhibitionSeller is Seller, SellableCallbacker {
    constructor(DiamondExhibition exhibition) SellableCallbacker(exhibition) {}

    /**
     * @notice Convenience function for inheriting sellers. Purchases tokens of given project IDs free-of-charge.
     */
    function _purchase(address to, uint8[] memory projectIds) internal {
        _purchase(
            to, uint64(projectIds.length), /* total cost */ 0, DiamondExhibitionLib.encodePurchaseData(projectIds)
        );
    }
}