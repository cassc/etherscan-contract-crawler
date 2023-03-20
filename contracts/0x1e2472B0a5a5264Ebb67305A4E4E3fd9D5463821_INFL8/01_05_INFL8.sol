// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Love Is In The Air
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    Love Is In The Air Series. Their hearts are made of air so don't go breaking wind.    //
//                                                                                          //
//                                                                                          //
//         .-.--.-.                                                                         //
//         { /_)(_\ }                                                                       //
//        { `}'X X/ `} DAISY BEE & CO.                                                      //
//         {`}\_0/{`}                                                                       //
//          `_J  L_`                                                                        //
//       ,'   `' -.\                                                                        //
//       / /Y  o)  o)\                                                                      //
//       / / \`-' `-'} )                                                                    //
//      ( {   \    // /                                                                     //
//       \ \  ;  . Y /                                                                      //
//        \ \/      Y                                                                       //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract INFL8 is ERC721Creator {
    constructor() ERC721Creator("Love Is In The Air", "INFL8") {}
}