// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manu Stegui
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxdKMMMMMMMMMMMMNx;;kWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'  'kWMMMMMMMMNx,   .oNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;     .kMMMMMWKd'      '0MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.   ..  ;OXMNOc.        .kMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0l:xNMMMMMMMMMW0:.   .oKd. ..co,    .:o;    oWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMk.   ,xNMMMMMWKc.   .dXMMNc        ,oKWWx.   ;XMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMo      ,xNMMXo.   .oXMMMMMXd.     .dNMMMNc   .kMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWl    ..  'lo'   .oXMMMMMMNOo'     ,kWMMMM0'   :NMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWc    cKk;.    .lKMMMMN0d:.     'cONMMMMMMWo   .kMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWl    lWMW0o,.:0WMWKxc'.    'ldkNMMMMMMMMMMK;   :XMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMo    oWMMMMNXNXkl,.    .,oONMMMMMMMMMMMMMMMk.  .dWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMx.   oWMMMNOo;.     .;d0WMMMMMMMMMMMMMMMMMMNl   .OMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMO.   lNKxc'      'cxXWMMMMMMMMMMMMMMMMMMMMMMK;   :XMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMX;   ';.     .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMO.  .oWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWo          .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.  .kMMKdc:ckNMMMMMMMM    //
//    MMMMMMMMMMMMO.  .od;..   .:d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   ;KWo    .kMMMMMMMM    //
//    MMMMMMMMMMMMXc  .xMWNKko;.  .,dKWMMMMMMMMMMMMMMMMMMMMMMMMMX:   lN0'    ;XMMMMMMM    //
//    MMMMMMMMMMMMNk.  cWMMMMMWKd,   .:kNMMMMMMMMMMMMMMMMMMMMMMMMK;  .OMO;..,dNMMMMMMM    //
//    MMMMMMMMMMMMXO:  '0MMMMMMMMNOc.   'dXMMMMMMMMMMMMMMMMMMMMMMMXl.,OMMWXKNMMMMMMMMM    //
//    MMMMMMMMMMMMN0d' .xMMMMMMMMXdc,.    .lOKKKKXXNNNWWWMMMMMMMMMMWXXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMOkl  cNMMMMMMMWO;  .''.   ........'',,;::cllodxk0KXNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0xx, ,KMMMMMMMMMNOc'.''.     .collc:;,'....      ..':coKMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNxko .kMMMMMMMMMMMWXx;.       .oXMMMMWNXXK0OOkxddooc'  lWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMkxO'.dWNXK0OOOOO00000xc'       ,0WMMMMMMMMMMMMMMMMWl  lWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXkxc.,ll;....      .....        .,;;:::ccclloooddxx:  cWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWX0XXK0OOkkxxddooolllcc:::;;,''......              cNMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXXKK000OOOkkkxxdxooKMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MSTEGUI is ERC721Creator {
    constructor() ERC721Creator("Manu Stegui", "MSTEGUI") {}
}