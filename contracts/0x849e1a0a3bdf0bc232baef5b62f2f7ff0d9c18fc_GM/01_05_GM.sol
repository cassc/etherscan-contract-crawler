// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Turbine
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                 __.-/|              //
//                 \`o_O'              //
//                  =( )=  +-----+     //
//                    U|  |  GM   |    //
//          /\  /\   / |   +-----+     //
//         ) /^\) ^\/ _)\     |        //
//         )   /^\/   _) \    |        //
//         )   _ /  / _)  \___|_       //
//     /\  )/\/ ||  | )_)\___,|))      //
//    <  >      |(,,) )__)    |        //
//     ||      /    \)___)\            //
//     | \____(      )___) )____       //
//      \______(_______;;;)__;;;)      //
//                                     //
//                                     //
/////////////////////////////////////////


contract GM is ERC721Creator {
    constructor() ERC721Creator("GM Turbine", "GM") {}
}