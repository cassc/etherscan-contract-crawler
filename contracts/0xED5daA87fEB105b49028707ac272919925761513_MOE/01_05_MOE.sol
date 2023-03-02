// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a series of unbelievable events
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    .................................................................'''''    //
//    .....................',,;;'........................................'''    //
//    ..................';ccccllc;'.''......    ...........................'    //
//    ................':llllc::::;'.';'         ...........................'    //
//    ............',:loocclc,.,::'. .          .............................    //
//    ........'clllllcc:::;.  .'.        ....'',,'..........................    //
//    ........,:,....,:::'.           .:ccccl:,'............................    //
//    ........';.   .....   ..      .;xOdl:ld:'.............................    //
//    ........',. .....    ...    .;lxkOxdoxOo,'............................    //
//    ........;,..............  .,lccokkoc:::,..............................    //
//    .......';............,,.....;;,ckOxdlc:,'.............................    //
//    ....................';'......':kK0Okkxoc;........',:c:,...............    //
//    ...............':lodo;'''.',cc:oOK00kocc,.......';lk00Oo,.............    //
//    ..............'oOOkxdlloccclooc,,:ccc;;,...'''',,ckOOOxc,.............    //
//    ............';oO0OOkxollllooollc;'.''....,cllloddx00Okdlc:;''......'''    //
//    .......':loxO0KK0000xldxdddooolc;........;dxdoxkkxkKKKXKKK0ko:,'''''''    //
//    ....;lxO0KKK00000OkdloO0OkOOOOxl,''......:OOOO0OxolxOKXXXXXXX0kdc;,'''    //
//    .'cx0KK000000OkO0kdc;o00OO0K00ko;,. .....,oOkO0koc,,lOXXXXXKKXXK0ko:,,    //
//    ;d0KK0OOkxddolcodl;'':k000KKKOxc,......',,ckkOOxlc;',o0XXK00KKKKKKKkl;    //
//    xKKK000Okdo:;:::;,'..;xKKKKKK0k:..',;'..'.;kOxxlcc;..'ckKK0000KKKK0Oo:    //
//    xKKK00Okxolc,',,,''..'lOKKKKK0O; .:lc;.   .oOdc:::;,,,,;lkOO0000OOkxlc    //
//    :kK00kddoll:;;,;;,,'..:xKKKKK0k,  ....     ,xxc:::;;::::loodxxxkxxdlcc    //
//    ':dkdolcccccdkOOkl;;;;,ckKKK0Ol.   ....    .:dlc:;;;:::oxolcclooool;;;    //
//    ,,:llcccccdOKXKK0xolloc;lx00kl.   ..''...   .;oc:;;:::lkK0Okxooolc:,,;    //
//    ,,;:clloox0KK0KOxkkkkOOxdddo;....,::cc::;,.. .;l:;;:c:dKNNNNXX00Oxolc:    //
//    ;,,;lkOOOOOOxk000OOOkxdoodo:..',;lxxxxkkxdl;'..;ccclllx0KXXXXKOkk00Od:    //
//    ::::codddlloxk000OOkdc;;,,,,''',:clodxkkxdlccloxkkxkkO0000KKKOdlloolc:    //
//    xdoolcc::::lkO00OOkdoc:;,,'....';:::coxxdoloxOOkxxk00KKK000K0Oxolc::::    //
//    KKK00kxocc:cdOOkkdlc:,,;;::,'..',::::cododxkxddddkKKKKK000000Oxlcc::::    //
//    kkxxxxxdolclxOkxo:,,'..';:::;'''',;:::::;:cdkkxk00KKK00OOOO0Okdl::::::    //
//    0OkxddooolcokOkdc,','...',;;;,''..',,,,,,',cx00KKKKK0OkkOOOOOkxl::cc::    //
//    0KKK0Okxdolc;;:;'..';. ..'','...........''',;lO000000kdox00OOkxl::cccc    //
//    odxkO00Okxd:.      .c:.......    ..'';:::::;,;lkOOOkxo:,lOOxdlc;;loooo    //
//    ccclloooooo:.       ;c'.       .,clllllcccc::::clooo:'';:;....  .xKK00    //
//    ccccccc::cc;.       ..      .';clllcccccc::::;;;::::,'';,.      .dXXXN    //
//    ccccccccccc:.              ':lllllcccccc:::::;;;;;;;;,'..       .oKKXX    //
//    cccccccccccl;.           .cddollllcccc::::::;;;;;;;;,,,..        'lkO0    //
//    cccccccccccoc.          .okkxdddollccc::::::;;;;;;;,,''..         'okk    //
//                                                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract MOE is ERC721Creator {
    constructor() ERC721Creator("a series of unbelievable events", "MOE") {}
}