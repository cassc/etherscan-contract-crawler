// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Te Waipounamu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    /////////////////////////////////    //
//    //                             //    //
//    //                             //    //
//    //        Te Waipounamu        //    //
//    //        South Island         //    //
//    //        Aotearoa             //    //
//    //                             //    //
//    //        Eth_iks              //    //
//    //                             //    //
//    //                             //    //
//    /////////////////////////////////    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TWP is ERC721Creator {
    constructor() ERC721Creator("Te Waipounamu", "TWP") {}
}