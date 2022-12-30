// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MetavelliART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                           ,ggg,  ,ggggggggggg,    ,ggggggggggggggg    //
//                                   I8                                        ,dPYb, ,dPYb,                dP""8I dP"""88""""""Y8, dP""""""88"""""""    //
//                                   I8                                        IP'`Yb IP'`Yb               dP   88 Yb,  88      `8b Yb,_    88           //
//                                88888888                                     I8  8I I8  8I  gg          dP    88  `"  88      ,8P  `""    88           //
//                                   I8                                        I8  8' I8  8'  ""         ,8'    88      88aaaad8P"          88           //
//      ,ggg,,ggg,,ggg,    ,ggg,     I8      ,gggg,gg     ggg    gg    ,ggg,   I8 dP  I8 dP   gg         d88888888      88""""Yb,           88           //
//     ,8" "8P" "8P" "8,  i8" "8i    I8     dP"  "Y8I    d8"Yb   88bg i8" "8i  I8dP   I8dP    88   __   ,8"     88      88     "8b          88           //
//     I8   8I   8I   8I  I8, ,8I   ,I8,   i8'    ,8I   dP  I8   8I   I8, ,8I  I8P    I8P     88  dP"  ,8P      Y8      88      `8i   gg,   88           //
//    ,dP   8I   8I   Yb, `YbadP'  ,d88b, ,d8,   ,d8b,,dP   I8, ,8I   `YbadP' ,d8b,_ ,d8b,_ _,88,_Yb,_,dP       `8b,    88       Yb,   "Yb,,8P           //
//    8P'   8I   8I   `Y8888P"Y88888P""Y88P"Y8888P"`Y88"     "Y8P"   888P"Y8888P'"Y888P'"Y888P""Y8 "Y8P"         `Y8    88        Y8     "Y8P'           //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTVart is ERC721Creator {
    constructor() ERC721Creator("MetavelliART", "MTVart") {}
}