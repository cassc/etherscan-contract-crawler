// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inject Memes Not Dope
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//     _,-'                   //
//        \\                  //
//         \\  ,              //
//         _,-'\              //
//        '\    \             //
//          \    \            //
//           \    \           //
//            \_,-'\          //
//             \_,-'\         //
//              \_,-'\        //
//               \_,-'        //
//                  \\        //
//                   \\       //
//                    \\      //
//                     \\     //
//                      \|    //
//                       `    //
//                            //
//                            //
////////////////////////////////


contract IMND is ERC721Creator {
    constructor() ERC721Creator("Inject Memes Not Dope", "IMND") {}
}