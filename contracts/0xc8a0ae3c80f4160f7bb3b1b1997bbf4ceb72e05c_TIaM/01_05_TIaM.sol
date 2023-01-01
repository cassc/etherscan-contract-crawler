// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Te Ika-a-Māui
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    /////////////////////////////////    //
//    //                             //    //
//    //                             //    //
//    //        Te Ika-a-Māui        //    //
//    //        North Island         //    //
//    //        Aotearoa             //    //
//    //                             //    //
//    //        Eth_iks              //    //
//    //                             //    //
//    //                             //    //
//    /////////////////////////////////    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TIaM is ERC721Creator {
    constructor() ERC721Creator(unicode"Te Ika-a-Māui", "TIaM") {}
}