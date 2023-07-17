// SPDX-License-Identifier: MIT

/// @title FOREVER MOMENTS by Daniel100.eth
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                              ◹◺
◹◺    This is my first mint from The Lab by Transient Labs.     ◹◺
◹◺                                                              ◹◺
◹◺    Team OFFSITE...                                           ◹◺
◹◺                                                              ◹◺
◹◺    Calistoga, 06/23/2023                                     ◹◺
◹◺                                                              ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract ForeverMoments is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2,
        "FOREVER MOMENTS",
        "4EVER",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}