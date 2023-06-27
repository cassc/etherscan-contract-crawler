// SPDX-License-Identifier: MIT

/// @title Lines by Marco Peyfuss
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                ◹◺
◹◺    _       _____  ______   ______  ______      ◹◺
◹◺    | |       | |  | |  \ \ | |     / |         ◹◺
◹◺    | |   _   | |  | |  | | | |---- '------.    ◹◺
◹◺    |_|__|_| _|_|_ |_|  |_| |_|____  ____|_/    ◹◺
◹◺                                                ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Lines is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2,
        "Lines",
        "LINES",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}