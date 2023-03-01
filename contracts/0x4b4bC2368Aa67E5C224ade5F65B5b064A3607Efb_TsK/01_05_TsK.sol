// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TsarKontrakt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      ____ __                                        //
//     /_ __/________ ______/ /______ _ ______ _       //
//      // / ___/ __ `/ ___/ //_/ __ \ | // __ `/      //
//     // (__ ) /_/ / / / ,< / /_/ / |/ / /_/ /        //
//    /_/ /____/\__,_/_/ /_/|_|\____/|___/\__,_/       //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract TsK is ERC721Creator {
    constructor() ERC721Creator("TsarKontrakt", "TsK") {}
}