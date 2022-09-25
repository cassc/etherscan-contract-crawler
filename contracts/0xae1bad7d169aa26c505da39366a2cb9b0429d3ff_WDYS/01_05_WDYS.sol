// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What do you say to me
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//    Xue is a little uncomfortable, auspicious words Lin Feng can say?                                                                                             //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//    Lin Feng mouth with a smile, said: "when the time comes I will say, I wish my father-in-law health and longevity, everything goes well, Fu Lu auspicious!"    //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//    Leaf clear snow Leng once, very is surprised, touch Lin Feng's forehead, say: "Lin Feng, you won't be silly? You really know how to talk?"                    //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WDYS is ERC721Creator {
    constructor() ERC721Creator("What do you say to me", "WDYS") {}
}