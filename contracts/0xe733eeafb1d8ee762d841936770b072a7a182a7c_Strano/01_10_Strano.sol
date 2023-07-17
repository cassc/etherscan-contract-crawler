// SPDX-License-Identifier: MIT

/// @title Strano by Strano
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                ◹◺
◹◺    ________________________________________    ◹◺
◹◺    ________________________________________    ◹◺
◹◺    ________________________________________    ◹◺
◹◺    __________/\                \___________    ◹◺
◹◺    _________/\\\    ___   ___   \__________    ◹◺
◹◺    ________/\\\\\   \ /\  \ /\   \_________    ◹◺
◹◺    _______/\\\\\\\   \__\  \__\   \________    ◹◺
◹◺    ______/\\\\\\\\\                \_______    ◹◺
◹◺    ______\\\\\\\\\\\________________\______    ◹◺
◹◺    _______\\\\\\\\\/________________/______    ◹◺
◹◺    ________\\\\\\\/________________/_______    ◹◺
◹◺    _________\\\\\/________________/________    ◹◺
◹◺    __________\\\/________________/_________    ◹◺
◹◺    ___________\/________________/__________    ◹◺
◹◺    ________________________________________    ◹◺
◹◺    ________________________________________    ◹◺
◹◺                                                ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Strano is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2,
        "Strano",
        "STRNO",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}