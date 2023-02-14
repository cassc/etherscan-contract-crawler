// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";
import "../interfaces/CloberOrderKey.sol";

library OrderKeyUtils {
    function encode(OrderKey memory orderKey) internal pure returns (uint256) {
        return encode(orderKey.isBid, orderKey.priceIndex, orderKey.orderIndex);
    }

    function encode(
        bool isBid,
        uint16 priceIndex,
        uint256 orderIndex
    ) internal pure returns (uint256 id) {
        if (orderIndex > type(uint232).max) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        assembly {
            id := add(orderIndex, add(shl(232, priceIndex), shl(248, isBid)))
        }
    }

    function decode(uint256 id) internal pure returns (OrderKey memory) {
        uint8 isBid;
        uint16 priceIndex;
        uint232 orderIndex;
        assembly {
            orderIndex := id
            priceIndex := shr(232, id)
            isBid := shr(248, id)
        }
        if (isBid > 1) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        return OrderKey({isBid: isBid == 1, priceIndex: priceIndex, orderIndex: orderIndex});
    }
}