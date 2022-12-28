// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: psyche
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNWMMMMMMM    //
//    MMMMMMMMMMMMMWX000KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK000KXWMMMMMMMMMWNKKKKNWMMMMMMMMMMMMMMMNKK00KNMM    //
//    MMMMMMMMMMMMMWX000KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK000KXWMMMMMMMMMWNKKKKNWMMMMMMMMMMMMMMMNKK00KNMM    //
//    MMMMMMMMMMMMMNKOOO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo''',xWMMMMMM    //
//    MMMMMMMMMMMMM0,   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'   ;KMMMMMMM    //
//    MMMMMMMMMMMMMO.   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   ;0MMMMMMMM    //
//    MMMMMMMMMMMMMO.   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl',lKMMMMMMMMM    //
//    MMWXKKKKNMMMMO.   .xWMMNKKKKKWMMMMWXKKKKXWMMMMMWXKKKKKXWMMMNK0OO0XWMMMMMMMWXK0KKXWMWX0KKNMMWKOxxkOKXWMMMMM    //
//    MM0;....dWMMMO.   .xWMM0;....xWMMMX:....:KMMMMMNo.....'kMMXl.   ..c0WMMMMWk,....dNM0;...c0x:..    ..cOWMMM    //
//    MMO'    lNMMMO.   .xWMMXc    ;XMMMK,    ,KMMMMMWk.     cNMX:       'kWMMNd.   .oNMM0'    .   ..      .oNMM    //
//    MM0'    lNMMMO.   .xWMMWx.   .OMMMK,    ,0MMMMMMK,     '0MW0kkd,    ,KMNo.   .dNMMM0'     .ck00kc.    .kMM    //
//    MMO.    lNMMMO.   .xWMMM0'   .dWMMK,    ,0MMMMMMNc     .kMMMMMMK:    l0l.   'kWMMMM0'    .xWMMMMNc     dWM    //
//    MM0'    lNMMMO.   .xWMMMK,    oWMMK,    ,KMMMMMMWl     .xMMMMMMM0'   ..    ;0WMMMMM0'    ,KMMMMMWo     oWM    //
//    MM0'    lNMMMO.   .xWMMMK,    oWMMK,    ,0MMMMMMNc     .kMMMMMMMWx.       cKMMMMMMM0'    ;XMMMMMWo     oWM    //
//    MMX;    ;XMMMO.   .xWMMWx.   .xMMMX:    .OMMMMMM0,     '0MMMMMMMMNc     .lNMMMMMMMM0'    ;XMMMMMWo     dWM    //
//    MMWd.   .c0NWO.   .dWNKd.    :XMMMWo.    :0NMWN0:      lNMMMMMMMWk'     .kMMMMMMMMM0'    ;XMMMMMWo     dWM    //
//    MMMNd.    .';,     ';'.    .lKMMMMMXc     .,;;,.    ..lXMMMMMMMWx.       ,0MMMMMMMM0'    ;XMMMMMWo     dWM    //
//    MMMMW0l'.               .'lONMMMMMMMXd,.          .:kKNMMMMMMMNd.   .'    :XMMMMMMM0'    ;XMMMMMWo     dWM    //
//    MMMMMMMN0kdlc,     'cldkKNWMMMMMMMMMMMN0xolccccldkKWMMMMMMMMMXl.   .k0,    lNMMMMMMNxooooONMMMMMWo     dWM    //
//    MMMMMMMMMMMMMO.   .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc    .kWWx.   .dNMMMMMMMMMMMMMMMMMMWo     dWM    //
//    MMMMMMMMMMMMMO.   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:    'kWMMNc    .;odxKMMMMMMMMMMMMMMWo     dWM    //
//    MMMMMMMMMMMMMO.   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0,    .kWMMMMKc       .xWMMMMMMMMMMMMMWo     dWM    //
//    MMMMMMMMMMMMM0;...'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:....,kWMMMMMMNx:.....;OMMMMMMMMMMMMMMWd.....xWM    //
//    MMMMMMMMMMMMMWX000KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK000KXWMMMMMMMMMWNKKKKNWMMMMMMMMMMMMMMMNKK00KNMM    //
//    MMMMMMMMMMMMMWX000KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK000KXWMMMMMMMMMWNKKKKNWMMMMMMMMMMMMMMMNKK00KNMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNWMMMMMMM    //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PSYCHE is ERC1155Creator {
    constructor() ERC1155Creator("psyche", "PSYCHE") {}
}