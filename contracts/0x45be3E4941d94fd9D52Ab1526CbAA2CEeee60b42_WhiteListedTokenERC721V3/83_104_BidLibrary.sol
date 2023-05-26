// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../tge/interfaces/IBEP20.sol";

library BidLibrary {
    /// @notice Information about the sender that placed a bid on an auction
    struct Bid {
        address payable bidder;
        uint256 bidAmount;
        uint256 actualBidAmount;
        uint256 bidTime;
    }

    function removeByIndex(Bid[] storage _list, uint256 _index) internal {
        for (uint256 i = _index; i < _list.length - 1; i++) {
            _list[i] = _list[i + 1];
        }
        _list.pop();
    }
}