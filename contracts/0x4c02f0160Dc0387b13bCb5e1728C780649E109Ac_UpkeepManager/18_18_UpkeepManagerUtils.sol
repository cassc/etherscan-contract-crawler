// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAvatarUtils} from "../BaseAvatarUtils.sol";
import {UpkeepManagerConstants} from "./UpkeepManagerConstants.sol";

contract UpkeepManagerUtils is BaseAvatarUtils, UpkeepManagerConstants {
    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL VIEW
    ////////////////////////////////////////////////////////////////////////////
    function getLinkAmountInEth(uint256 _linkAmount) internal view returns (uint256 ethAmount_) {
        uint256 linkInEth = fetchPriceFromClFeed(LINK_ETH_FEED, CL_FEED_HEARTBEAT_LINK);
        ethAmount_ = (_linkAmount * linkInEth) / 1 ether;
    }
}