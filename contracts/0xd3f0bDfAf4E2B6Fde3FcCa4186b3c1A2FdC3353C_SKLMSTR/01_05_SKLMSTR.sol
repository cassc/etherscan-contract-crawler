// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SKULLMASTER
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOkxdddoooooooodddxkOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXKkdolc::;,,,,,,,,''',,,,,;::clodk0XXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXX0xol:;,,,,''..................''',,,;:lox0XXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXOdl:;,,'...    ..............       ....',,;:ldOXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXX0dc;,,,....';:loddxxxxxxxxxxxxxxdolc;,..    ...,,,;cd0XXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXOl:,;,...;ldxkxxxddddddddxdxdxxxxxxxxkkkkxdc,..   ..,,,:lOXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXkl;;;'..:dkxxxodxdkO0KXXXXXXXXXXXXXXK0OkkxxkkOOkd:.    .';;;lkXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXOl;;;...cOOkdlxKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOOO00Ol'    ..,;;lOXXXXXXXXXXXX    //
//    XXXXXXXXXXKd;;;.. ,k0xdOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKX0:.    ..;;;dKXXXXXXXXXX    //
//    XXXXXXXXXOc,;,.  'kKdd0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKc.     .';,cOXXXXXXXXX    //
//    XXXXXXXXk;,;..  .lXko0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNO,      ..;,;kXXXXXXXX    //
//    XXXXXXXx;;;.    .dXxxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK:        .;;;xXXXXXXX    //
//    XXXXXXx,;;.     .dXxxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK:         .,;,xXXXXXX    //
//    XXXXXk;;;.      .xXxxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK:          .;;;kXXXXX    //
//    XXXX0:,;.       .xXxxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK:           .;,:0XXXX    //
//    XXXXo,;'        .xXxkXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK;            ';,oXXXX    //
//    XXNO;;;.        .xKdkXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK:.           .;;;ONXX    //
//    XXXd,;'      ..,cOX00XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNXXXXKKK0000kxdol:,.      ';,oXXX    //
//    XXKc,;.   .,ok0XXXKxodddddxxxxxxxxxxxxxxxxxOOk0KKXXK0kkxxxxxxxxxxxxxxkkOOOOOko'    .;,cKXX    //
//    XN0;,;. .,xKXXXXXXKo:ccc:c:c:::::cclooxkkOkkkxxxddxdxdxkOO0KKXXXXXXXXXXXXK00KXO'   .;,;ONX    //
//    XNO;;,. ,OKKXXXXXXKo::::cccllddkkOOkOxxxdxddxdxOOKXXXXXXXXXXXXXXXXXXXXXXXXXXXN0;   .,;;kNX    //
//    XNk;;,. :KOok0XXXNXkxkkkOOOOkkxxddxodxxO0KXXNNNXXXK0Okxdolcc:;;,,,,;lOXXXXXXKk:.   .,;;kNX    //
//    XNO;;;. .dKkllloddxxxddoolollddkO0XXXNNXXKOkdooc:,'....              .;;:::;'.     .,;;ONX    //
//    XN0:,;.  .;dO0OxddooddxxkOKXXNXXK0Oxdoc:,'..                              ......   .;,:0NX    //
//    XXXl,:.    ..;coddxxkkkxxdoolc:;,,;;;::ccc:;;,,'....                  .,cdxkOOo.   .:,lXXX    //
//    XXNx,;,.       .':odxxdc,.   .'cdOKXXXXXXXXXXXKK0Okxddollcc::::::::::cxKNNXKxc.   .,;,xXXX    //
//    XXXKc,;.      .:0XXXXXXXKxlclxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKkl,.     .;,cKXXX    //
//    XXXXx,;,.     .cKXXKOxxxOKNXXXXXKxlc:;;;;:clodk0XXXXXXXXXXXXXXXXXKK000KXXKOxc'.  .,;,xXXXX    //
//    XXXXXo,;'.     ;0kc'.....cKXXXXKc.            .'oKXXXXXXXXX0xoc:;,''..,lk0KXX0l. ';,oXXXXX    //
//    XXXXXKc,;'     .xo.      ,ONXXX0;             .:kXXXXXXXOo;..           ..,;;:;..:,cKXXXXX    //
//    XXXXXX0c,;'.   .oKo.    .cOxkKXXx'.      ..,ldkKXXXXXXkc.                      .;,c0XXXXXX    //
//    XXXXXXX0c,;'.  .dXXOo:;;lx:..;xKX0dc:;;cldOKXXXXXXXKk:.                      .';,c0XXXXXXX    //
//    XXXXXXXXKo,;,. .;d0XNXXXXl.   .;xKXXXXXXXXXXXXXXX0d;.                       .,;,oKXXXXXXXX    //
//    XXXXXXXXXXx:,;'. .':oxO0k'      .;d0XXXXXXK0Okxl:'.                       .';,;xXXXXXXXXXX    //
//    XXXXXXXXXXX0o;;;..   .....        ..,;:::;,'...                         ..;;;l0XXXXXXXXXXX    //
//    XXXXXXXXXXXXXOc;;,..                                                  ..,;;cOXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXkl;;;'..                                            ..';,;lkXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXOo:;,,'..                                      ..',,;:oOXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXKxl:;,,'...                              ...',,;:lxKXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXKkoc:;,,,'....                  ....',,,;:cokKXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXX0xolc:;,,,,'''''......''''',,,,;:clox0XXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kdoollcc::::::::::ccllooxk0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK000OOOO000KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKLMSTR is ERC721Creator {
    constructor() ERC721Creator("SKULLMASTER", "SKLMSTR") {}
}