// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fast Food Pups UFO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllcc;;:c::c::cllllllllllll    //
//    llllllllllllllllllc;,;:;,,,:lollolc:::;,;cllllll    //
//    lllllllllllllllll;'..'',,,;ldcldcld:,,'..';cllll    //
//    llllllllllllllllc'.;lc'.''',,',,,,;''',;;',cllll    //
//    lllllllllllllllll,.,;.  ..',,,,,,,,,'. .,',cllll    //
//    llllll:,',:lllllllc,;:';ll:;;;;;;;;;cc..':llllll    //
//    lllll;.....,llllllc:,',lko,.........:o..clllllll    //
//    lllllc,... .clllll:....'codxxxxxxxxdl,.,clllllll    //
//    llllll;.....,:llcl;.....';dkdc;;;lxx;.,lllllllll    //
//    llllllc;'..........  ... .:xxl'.;oxd,.;lllllllll    //
//    llllllllc,..''.............,cc:;:c:' .;lllllllll    //
//    lllllllll;..',,'''','''''''..........':lllllllll    //
//    lllllllll;..',,''',,,,'','',,''....':lllllllllll    //
//    lllllllll;..''..........'''..'..,::lllllllllllll    //
//    lllllllll;..''.    .'. .'''. ...;lllllllllllllll    //
//    lllllllll;..''. ...,c;..'''. ...,cllllllllllllll    //
//    lllllllll:......  ..':'......  ..'clllllllllllll    //
//    llllllllllc;'.....'';cc;'''......;clllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract FUO is ERC1155Creator {
    constructor() ERC1155Creator("Fast Food Pups UFO", "FUO") {}
}