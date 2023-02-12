// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: eXistenZ by Alexander Déboir
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                  ,                    _                                             //
//                /'/                  /' `\              /'                           //
//              /' /                 /'     )           /'                             //
//           ,/'  /                /'      /'____     /'__     ____     O   ____       //
//          /`--,/               /'      /'/'    )  /'    )  /'    )--/'  )'    )--    //
//        /'    /              /'      /'/(___,/' /'    /' /'    /' /'  /'             //
//    (,/'     (_,   O     (,/' (___,/' (________(___,/(__(___,/'  (__/'               //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract EXZ is ERC721Creator {
    constructor() ERC721Creator(unicode"eXistenZ by Alexander Déboir", "EXZ") {}
}