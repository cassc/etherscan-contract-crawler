// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zey's
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//     ,*******,       ,*******,  ,****,         **                   //
//    ***""""""***,   ,**""""""*****""***        **                   //
//    **,_*     `**   **'    *  ****, `**        **                   //
//    `***"      **   **     "***' `"  **        **                   //
//               **   `******          **        **                   //
//              **'  ,***""""          **        **                   //
//           _,**'   **"               **       ,**                   //
//         *******,  **,               ***,___,****                   //
//             "****,`***,,_____,       "*******"**,                  //
//             ,*****  `"********            ,*****                   //
//           ,**"  **                       ***" **                   //
//          **'    **                     ,**'   **                   //
//         dS'    ,**                     **'    **                   //
//         **     **'                     **     **                   //
//         **,_ _,**                      **,_ _,**                   //
//          "*****"                        "*****"                    //
//                                                                    //
//                                                                    //
//    being me is to flow tirelessly from blinding brightness         //
//    to blinding darkness in a second.                               //
//    i never belong to this world,                                   //
//    i’ve been living in my own reality since i exist.               //
//    i’m full of dreams, emotions, senses and that’s all.            //
//    i don’t believe in thoughts,                                    //
//    i believe in feelings so my art always comes from my heart.     //
//    i intend to make people feel how i feel                         //
//    and express my own reality                                      //
//    just the way it is.                                             //
//                                                                    //
//    this smart contract includes 1/1 narratives of zey.             //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract zey is ERC721Creator {
    constructor() ERC721Creator("zey's", "zey") {}
}