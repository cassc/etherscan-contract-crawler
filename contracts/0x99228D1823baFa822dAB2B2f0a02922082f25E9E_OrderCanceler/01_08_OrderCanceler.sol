// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./interfaces/CloberOrderCanceler.sol";

contract OrderCanceler is CloberOrderCanceler {
    function cancel(CancelParams[] calldata paramsList) external {
        _cancelTo(paramsList, msg.sender);
    }

    function cancelTo(CancelParams[] calldata paramsList, address to) external {
        _cancelTo(paramsList, to);
    }

    function _cancelTo(CancelParams[] calldata paramsList, address to) internal {
        for (uint256 i = 0; i < paramsList.length; ++i) {
            uint256[] calldata tokenIds = paramsList[i].tokenIds;
            CloberOrderBook market = CloberOrderBook(paramsList[i].market);
            CloberOrderNFT(market.orderToken()).cancel(msg.sender, tokenIds, to);
        }
    }
}