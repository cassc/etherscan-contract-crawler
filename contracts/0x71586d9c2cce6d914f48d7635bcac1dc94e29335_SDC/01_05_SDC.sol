// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIGHTSEERS - Director's Cut
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//            ##         h)        t)                                               //
//                       h)      t)tTTT                                             //
//     s)SSSS i)  g)GGG  h)HHHH    t)    s)SSSS e)EEEEE e)EEEEE  r)RRR   s)SSSS     //
//    s)SSSS  i) g)   GG h)   HH   t)   s)SSSS  e)EEEE  e)EEEE  r)   RR s)SSSS      //
//         s) i) g)   GG h)   HH   t)        s) e)      e)      r)           s)     //
//    s)SSSS  i)  g)GGGG h)   HH   t)T  s)SSSS   e)EEEE  e)EEEE r)      s)SSSS      //
//                    GG                                                            //
//               g)GGGG                                                             //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract SDC is ERC721Creator {
    constructor() ERC721Creator("SIGHTSEERS - Director's Cut", "SDC") {}
}