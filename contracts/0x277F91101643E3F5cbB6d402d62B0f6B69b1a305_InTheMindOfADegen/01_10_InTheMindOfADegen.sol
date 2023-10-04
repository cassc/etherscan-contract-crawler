// SPDX-License-Identifier: MIT

/// @title In the mind of a degen
/// @author transientlabs.xyz

/*//////////////////////////////////////////////////////////////////////
//                                                                    //
//    _       _   _______ _____  _____  _____    _       _            //
//      /\| |/\ /\| |/\__   __|  __ \|  __ \|  __ \/\| |/\ /\| |/\    //
//      \ ` ' / \ ` ' /  | |  | |__) | |  | | |__) \ ` ' / \ ` ' /    //
//     |_     _|_     _| | |  |  _  /| |  | |  _  /_     _|_     _|   //
//      / , . \ / , . \  | |  | | \ \| |__| | | \ \/ , . \ / , . \    //
//      \/|_|\/ \/|_|\/  |_|  |_|  \_\_____/|_|  \_\/|_|\/ \/|_|\/    //
//                                                                    //
//     I N  T H E  M I N D  O F  A  D E G E N  - B Y  P A I N T R E   //
//                                                                    //
//////////////////////////////////////////////////////////////////////*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract InTheMindOfADegen is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "In the mind of a degen",
        "TRDR",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}