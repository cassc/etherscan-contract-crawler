// SPDX-License-Identifier: MIT

/// @title DEGENPAIN by DEGENPAIN
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                ◹◺
◹◺    PPPPPPPP    AAAAAA   IIIIIII  NNNN    NN    ◹◺
◹◺    PP     PP  AA    AA     II    NN NN   NN    ◹◺
◹◺    PPPPPPPP  AAAAAAAAA    II    NN  NN  NN     ◹◺
◹◺    PP        AA      AA   II    NN   NN NN     ◹◺
◹◺    PP        AA      AA IIIIIII NN    NNNN     ◹◺
◹◺                                                ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Degenpain is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2,
        "DEGENPAIN",
        "PAIN",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}