// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nourriture pour l’âme
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//     ,ggg, ,ggggggg,   ,ggggggggggg,       ,gggg,             ,ggg,      //
//    dP""Y8,8P"""""Y8b dP"""88""""""Y8,    d8" "8I            dP""8I      //
//    Yb, `8dP'     `88 Yb,  88      `8b    88  ,dP           dP   88      //
//     D"  88A       88  `A  88      ,8P 8888888P"           dP    88      //
//         88        88      88aaaad8PN     88              ,8'    88      //
//         88        88      88"""""        88              d88888888      //
//         88        88      88        ,aa,_88        __   ,8"     88      //
//         88        88      88       dP" "88P       dP"  ,8P      Y8      //
//         88        Y8,     88       Yb,_,d88b,,_   Yb,_,dP       `8b,    //
//         88        `Y8     88        "Y8P"  "Y88888 "Y8P"         `YS    //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract NPLA is ERC721Creator {
    constructor() ERC721Creator(unicode"Nourriture pour l’âme", "NPLA") {}
}