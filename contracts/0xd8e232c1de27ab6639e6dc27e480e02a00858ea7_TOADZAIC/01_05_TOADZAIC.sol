// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toadzaic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                TOADZAIC                                                    //
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:',',,''''''''''''''''''',,'''',':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkolccccccccccccccccccccccccccccccccccookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWXKk;.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.;kKXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNc.,kXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKk,.cNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMX;  ,::::::::::::oXM0c:::::::::::::kWMMMMMMO. ;XMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMKkxc;'        .,,;,lXMx.        ';,,;xWMMMMMMKc,cxkKMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNNl..xM0,      .dWWWWWMMx.       'OMWWWMMMMMMMMMMWx. lNNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMO;'lO0NMWKOOOOOO0XMMMMMMMN0OOOOOOO0NMMMMMMMMMMMMMMMx. .',OMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXxl,  'llllllllllllllllllllllllllllllllllllllllldKMMMMx. .clllxXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWK0x;..     .....................................  .kMMMMx. lWNl.;x0KWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX: ,ONo     oXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK: .kMMMMx. lWMNXO, :XMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx;:oxONMd.    .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;. .kMMMMx. lWMMMNOxo:;xWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNc .kMMMM0c;.  .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c0MMMMx. lWMMMMMMk. cNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNc .kMMMMMMWo..dXNWMMMMMMMNXNWMMMMWNXWMMMMMWNXNMMMMMMMMMMWNXd..oWMMMMMMk. cNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNc .kMMMMMMMX0Oc.:0MMMMMMWo.;OMMMMk,'xWWMMMKc.lXMMMMMMMMM0:.cO0XMMMMMMMk. cNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWOlllcxXMMMMMMWklllcxNMMMWOlllcxXMx. lNWWkclllkNMMMMMMNxclllkWMMMMMMMMMk. cNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXl':xOOOOOO0NMKc':xOOOOOOx. '0Mx. lNWX; .oOOOOOOOOOk:':xOOOOOO0NMWKOd;'dWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNNk'      .xMMWNx. ..      '0Mx. lNWX:          . .xNk'      .xM0, ;0NWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNo,:dkkkkkxkXMMMMXOxkkx'  ckONMx. lNWW0ko. .okxkkkxOXMNOxkkkkkxc;:dk0WMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNd:codddddddddddddddddo'  :dddd;  ,oodddc. .lddddddddddddddddddc:oKMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0,..........................................................kMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TOADZAIC is ERC721Creator {
    constructor() ERC721Creator("Toadzaic", "TOADZAIC") {}
}