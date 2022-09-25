// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: flower carving to Jia Mu
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//    this is twenty years' worth of Shaoxing flower carving. How do you like it?"                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//    Jia mother took a look at the glass, gently took a sip, and nodded with satisfaction, "The color of the wine is orange and clear, the entrance is soft, the wine is fragrant and fragrant, the wine is sweet and mellow, very good, these dishes look good, your child has a heart."    //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//    When the old lady was so satisfied, Jia Cong smiled and said, "If she is satisfied, please see which dish you want and your grandson will bring it to you."                                                                                                                             //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
//    After all, Jia's mother is old and has a very small appetite. She only ate some stewed deer tendon in claypot, sweet-scented osmanthus fish sticks, sliced fish in ginger sauce, and tasted a piece of Suckling pig with skin. Then she put down her chopsticks and stopped eating.     //
//                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FCTJM is ERC721Creator {
    constructor() ERC721Creator("flower carving to Jia Mu", "FCTJM") {}
}