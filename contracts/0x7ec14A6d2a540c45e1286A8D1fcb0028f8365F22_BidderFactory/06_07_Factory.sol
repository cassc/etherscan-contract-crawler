// SPDX-License-Identifier: GPL-3.0

import {Bidder} from "./Bidder.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {INounsAuctionHouse} from "./external/interfaces/INounsAuctionHouse.sol";

pragma solidity 0.8.17;

contract BidderFactory {
    event CreateBidder(address b);

    function deploy(address t, address ah, address _owner, Bidder.Config memory cfg)
        external
        payable
        returns (address)
    {
        Bidder b = new Bidder{value: msg.value}(IERC721(t), INounsAuctionHouse(ah), _owner, cfg);

        emit CreateBidder(address(b));

        return address(b);
    }
}