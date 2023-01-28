// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rogflections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOkkxxxddddddoooooooooooooddddddxxxxkkkOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0d,.................................''',,;;:::lxOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0l.       ......                 ........ ... .o0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0o. .                                       . .d0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0d. .                                       . .d0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0x. .                                       . 'x0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0k' .                                         ,k0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0k,                ROGFLECTIONS               ;OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOO:                                        .  cOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOc  .                                     . .l0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOO0l. .                by @penguin_curator  . .d0OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOO0OOOkkxxc. .                                     . .okkOOO00OOOOOOOOO    //
//    OOOOO0Oxdlcc:;,''...                                          ...',;:cloxkOOOOOO    //
//    OOOOxc,.............                                          ...........';lkOOO    //
//    OOOOd'..................                                 ..................;xOOO    //
//    OOOOOkoc;,.......................             .......................',;cldkOOOO    //
//    OOOOOOO0OOkxolcc'       ...............................'',;::c:';lodxkOO0OOOOOOO    //
//    OOOOOOOOOOOOOO0O;  .    :0K00OOOOkkkkkkkkkkkkkkOOOO00KKXXNWWWMKco0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOO0d. .  . .xWMMMMMMMMWX0KKNMMMMMMMMMMMMMMMMWXK0KWK:l0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOO0o. .  . .OMMMMMMMMMN0O00KXNMMMMMMMMMMMMMMNKKKKNK::OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOO0d. .    .xMMMMMMMMWXKKKXWWMMMMMNXKKKK0XWMMWKOO0Nk,cOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOO0k' .     :XMMMMMMW0occclxOXMMMWKkxxxxk0NMWKocldXWd'd0OOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOl. .    .oNMMMMMMNKOkkk0KNMMMMWNKKKKNWMMMWXXXWWM0,c0OOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOk;  .    .oNMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMM0;l0OOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOO0k,       .cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd:k0OOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOx'       .,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOlx0OOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOO0O;         .:xOXWMMMMMMMMMMMMMMMMMMMMMMMMMMXl,d0OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOx:.            ..;lkXWMMMMMMMMMMMMMMMMMMMMNx,  'cxOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOx:.                  ..;ldkKXNN0O0XWMMMMNKkx:.     .;dOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOo.                         .,okl,,,;oONN0l;,,..       .oOOOOOOOOOO    //
//    OOOOOOOOOOOOOo.                            .,'',,,,,::;',,,..        .o0OOOOOOOO    //
//    OOOOOOOOOOOOd.                               ..,,,'..,,'.','.         'xOOOOOOOO    //
//    OOOOOOOOOO0k,              .                  .,,,''ckxc,','.          ;kOOOOOOO    //
//    OOOOOOOOOOOc.                                  ...'ok0Xx,...           .o0OOOOOO    //
//    OOOOOOOOO0k,                                       .;OK:                ;OOOOOOO    //
//    OOOOOOOOO0d.                                         ;c.                .d0OOOOO    //
//    OOOOOOOOOOc.                                                            .l0OOOOO    //
//    OOOOOOOOOO;                                                              :OOOOOO    //
//    OOOOOOOO0k,                                                              ;O0OOOO    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ROGF is ERC721Creator {
    constructor() ERC721Creator("Rogflections", "ROGF") {}
}