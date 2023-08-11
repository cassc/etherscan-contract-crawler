// SPDX-License-Identifier: MIT

/// @title Underbelly by Sunken0x
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                    ◹◺
◹◺    01110111 01100101 01101100 01100011 01101111    ◹◺
◹◺    01101101 01100101 00100000 01110100 01101111    ◹◺
◹◺    00100000 01110100 01101000 01100101 00100000    ◹◺
◹◺    01110101 01101110 01100100 01100101 01110010    ◹◺
◹◺    00100000 01100010 01100101 01101100 01101100    ◹◺
◹◺    1111001                                         ◹◺
◹◺                                                    ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Underbelly is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Underbelly",
        "UNDER",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}