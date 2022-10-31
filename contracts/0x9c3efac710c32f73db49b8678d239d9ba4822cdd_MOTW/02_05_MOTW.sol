// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimals of the West
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ,`""',                 //
//          ;' ` ;           //
//          ;`,',;           //
//          ;' ` ;           //
//     ,,,  ;`,',;           //
//    ;,` ; ;' ` ;   ,',     //
//    ;`,'; ;`,',;  ;,' ;    //
//    ;',`; ;` ' ; ;`'`';    //
//    ;` '',''` `,',`',;     //
//     `''`'; ', ;`'`'       //
//          ;' `';           //
//          ;` ' ;           //
//          ;' `';           //
//          ;` ' ;           //
//          ; ',';           //
//          ;,' ';           //
//                           //
//                           //
///////////////////////////////


contract MOTW is ERC721Creator {
    constructor() ERC721Creator("Minimals of the West", "MOTW") {}
}