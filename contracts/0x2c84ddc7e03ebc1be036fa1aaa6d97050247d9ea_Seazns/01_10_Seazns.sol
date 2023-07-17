// SPDX-License-Identifier: MIT

/// @title Seazns by redactedpride
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                                                                                    ◹◺
◹◺    In a quaint garden nestled between towering trees, a symphony of flowers came alive, painting                   ◹◺
◹◺    the canvas of the changing seasons.                                                                             ◹◺
◹◺                                                                                                                    ◹◺
◹◺    As autumn arrived, a quiet transformation began. Hardy Fuchsia emerged as other blooms                          ◹◺
◹◺    surrendered their brilliance to the passage of time. Leaves turned falling gently to the ground                 ◹◺
◹◺    like confetti bidding farewell to summer's warmth.                                                              ◹◺
◹◺                                                                                                                    ◹◺
◹◺    Winter wrapped the garden in a frosty embrace, blanketing the earth with a pristine coat of white as the        ◹◺
◹◺    primrose take their stations. The winter soldiers guard as the others lay dormant beneath the frozen ground,    ◹◺
◹◺    a quiet promise of renewal held within their delicate petals.                                                   ◹◺
◹◺                                                                                                                    ◹◺
◹◺    Spring awakened with towering tulips with their vibrant burst of colors and delicate blossoms.                  ◹◺
◹◺    Their petals unfurling to embrace the warm kiss of the sun. The air danced with the fragrance,                  ◹◺
◹◺    captivating all who ventured near.                                                                              ◹◺
◹◺                                                                                                                    ◹◺
◹◺    As summer claimed its reign, the garden transformed into a maze of yellow and gold. Sunflowers                  ◹◺
◹◺    reached for the heavens, their golden faces beaming with joy. Petals of electrifying yellow                     ◹◺
◹◺    whispered tales of adventure and effervescent joy. The air buzzed with the melodies of busy bees                ◹◺
◹◺    and butterflies, their delicate wings fluttering among the floral tapestry.                                     ◹◺
◹◺                                                                                                                    ◹◺
◹◺                                                                                                                    ◹◺
◹◺    And so, the garden became a testament to the resilience of nature, to the bittersweet dance of                  ◹◺
◹◺    life and death. Each season brought forth a new chapter, a fleeting but exquisite story of flowers              ◹◺
◹◺    blooming and dying, leavingbehind a legacy of beauty and a reminder that in every ending, there is              ◹◺
◹◺    the promise of a new beginning.                                                                                 ◹◺
◹◺                                                                                                                    ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Seazns is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xAa6AB798c96f347f079Dd2148d694c423aea8C81,
        "Seazns",
        "SZNS",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}