// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wealthy Totem
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//           &&&&&&&      //
//          &&(+.+)&&     //
//          ___\=/___     //
//         (|_ ~~~ _|)    //
//            )___(       //
//          /'     `\     //
//         ~~~~~~~~~~~    //
//         `~//~~~\\~'    //
//          /_)   (_\     //
//                        //
//                        //
////////////////////////////


contract WEALTH is ERC721Creator {
    constructor() ERC721Creator("Wealthy Totem", "WEALTH") {}
}