// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: warbb
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//                                                                                    //
//       ________  ________  ________  ________  ________                             //
//      ╱  ╱  ╱  ╲╱        ╲╱        ╲╱       ╱ ╱       ╱                             //
//     ╱         ╱         ╱         ╱        ╲╱        ╲                             //
//    ╱         ╱         ╱        _╱         ╱         ╱                             //
//    ╲________╱╲___╱____╱╲____╱___╱╲________╱╲________╱                              //
//                                                                                    //
//                                                                                    //
//    WARBB. IS A DIGITAL ARTIST.                                                     //
//    ﻿THE ART CAN BE DEFIED AS COLORFUL MIXED WITH DEPTH AND FREEDOM.                //
//    ﻿THE FREEDOM TO LET YOUR IMAGINATION RUN WILD AND SEE IT AS YOU PERCEIVE IT.    //
//    ﻿THAT IS WHY ROBBIN SNIJDERS A.K.A. WARBB. STARTED MAKING ART.                  //
//    ﻿CREATIVE FREEDOM.                                                              //
//    ﻿WITHOUT RESTRICTIONS, OPINIONS OR CONCESSIONS.                                 //
//    ﻿PURE FREEDOM AND PURE BEAUTY.                                                  //
//                                                                                    //
//    WWW.WARBB.COM                                                                   //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract warbb is ERC721Creator {
    constructor() ERC721Creator("warbb", "warbb") {}
}