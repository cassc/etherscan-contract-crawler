// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marterium
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                                   .........                                        .........                                    //
//                                  ,0XXXXXXXKx;                                   .;xKXXXXXXX0,                                   //
//                                  ;XMMMMMMMMMNO:.                              .:OWMMMMMMMMMX;                                   //
//                                  ;XMMMMMMMMMMMW0c.                          .l0WMMMMMMMMMMMX;                                   //
//                                  ;XMMMMMMMMMMMMMWKl.                      'oKWMMMMMMMMMMMMMX;                                   //
//                                  ;XMMMMMMMMMMMMMMMMXd'                  ,dXMMMMMMMMMMMMMMMMX;                                   //
//                                  ;XMMMMMMM0kXMMMMMMMMXx,              ;kNMMMMMMMMXk0MMMMMMMX;                                   //
//                                  ;XMMMMMMMo.'dXMMMMMMMMNk;         .:ONMMMMMMMWKo'.dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo   .l0WMMMMMMMNO:.    .c0WMMMMMMMW0l.   dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo     .:ONMMMMMMMNc    cNMMMMMMMNO:.     dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo        ;kNMMMMMWl    cWMMMMMNx;        dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo          ,dXMMMWl    cWMMMXd'          dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo            .oKWWl    cWWKl.            dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo              .cOc    :kc.              dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo                ..    ..                dMMMMMMMX;                                   //
//                                  ;XMMMMMMMo                                        dMMMMMMMX;                                   //
//                                  .cooooool'                                        'looooooc.                                   //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MARTM is ERC721Creator {
    constructor() ERC721Creator("Marterium", "MARTM") {}
}