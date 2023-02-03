// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JeVa Limited
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    MMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMMM    //
//    MMM0OWWWMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMWM0OWMMM    //
//    MMM0lkKONMMMMMMMMMMMMMMM00WX000KW0OWMMMMMMMMMMMMMMMK0KlxMMMM    //
//    MMMWl;kllXMMMMMMMMMMMMMMd,;.   .,'oWMMMMMMMMMMMMMWk:xl:KMMMM    //
//    MMMMK;,;.,xXWMMMWNK0OxkN0'       .OW0xk0KXNWMMMW0c.';'xMMMMM    //
//    MMMMMO'    .:c:;'...   'dd.     .ok:.   ..',:c:,.   .dWMMMMM    //
//    MMMMMMKc.                ;l.   .ll.                ,kWMMMMMM    //
//    MMMMMMMNx:'.        ..';:';o;,cdl.;c;'..        .,l0WMMMMMMM    //
//    MMMMMMMMMMNKxl'        .:dk0NNMXOOd,.       .;lkKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMWO;         .lXMMMMK:         .c0WMMMMMMMMMMMMM    //
//    MMMMMMMMWWWXd;.            lNMMK;            .;dXMWWMMMMMMMM    //
//    MMMMMMMMN0k;               .xWXl                ;OKXMMMMMMMM    //
//    MMMMMMMMNo.        ..       :Od,      .'.        .oXMMMMMMMM    //
//    MMMMMMMMWo        .kXc      'c;.     .dNk.        oWMMMMMMMM    //
//    MMMMMMMMMK,       dWMK;     .;'.     lNMMd       '0MMMMMMMMM    //
//    MMMMMMMMMWk.     .kMMM0'    .;'.    :XMMMk.     .xWMMMMMMMMM    //
//    MMMMMMMMMMWx.    .xMMMWx.   .;'.   '0MMMMx.    .xWMMMMMMMMMM    //
//    MMMMMMMMMMMWx.    cWMMMNl   .;'.  .xWMMMWc    .xWMMMMMMMMMMM    //
//    MMMMMMMMMMMMWO,   'OMMMMK,  .;'.  cNMMMM0'   ,OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXc.  cNMMMWx. .;'. '0MMMMNl  .cXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx. .xWMMMN: .;'. oWMMMWx. .xNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0, '0MMMMk..:'.,KMMMM0, ,0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXl.:XMMMNc';'.oWMMMX:.lXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWx'cNMMMx;,':0MMMNc'xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0:oNMMXd::xWMMNo:0MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXdxNMWKkOXMMNxdXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNOONMWWWMMNOONMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMWXXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract JeVaLim is ERC721Creator {
    constructor() ERC721Creator("JeVa Limited", "JeVaLim") {}
}