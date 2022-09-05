// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MintCards
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllccccccccccccccccccccccccllllcclccllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllc'.................................'cllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllll:.                                 .:llllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc;''''...................................''',:llllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllll:.    ':::::::::::::::::::::::::::::::::'    .clllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc:::;.   .':::::::::::::::::::::::::::::::::'.   .::::clllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc'   .';;;;:::::::::::::::::::::::::::::::::::;;;,.   .;lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    ':::::::::::::::::::::::::::::::::::::::::::.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll:'........';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,'........':llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll,    .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.   .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll,    .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.   .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll,    .',,,;::::;,,,,::::;,,,,;:::::;,,,,:::::,,,,;::::;,,,'.   .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllll,    .,,,;:ccc:;,,,;:ccc:;,,,;cccc:;,,,;:ccc:;,,,;:cc:;,,,'.   .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllc;,,;oOOOO00000OOOOO00000OOOO000000OOOOO00000OOOOO00000OOOkl,,,;cllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllONWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNklllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllONWWNKOOOOOOOOOOOOOKNWWNX0O000000000000KNWWWWWWWNOdooollllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllONWWXxcccccccccccccxXWWNOollllllllllllldKWWWWWWWNc    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllONWWXxcccccccc:ccccxXWWNOlllllllllllllldKWWWNNNNXl....,:::clllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllloONWWXxccccccccc:wenxXWWNOlllllllllllllldKWWWX000Okxddo'   .:llllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllONWWXxcccccccccccccxXWWNOllllllllllmintdKWWWXOOOOOOOOx'   .;llllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllloONWWNKOOOOOOOOOOOOOKNWWNX00000000000000KNWWWXOOOOOOOOx'   .;llllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllONWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX0OOOOOOOx'   .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllloxxxk0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOOOOdlcl:.   .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc'   .cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOk;        .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    cOOOOOOOOOkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOk;        .;llllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc'    cOOOOOOOOd;.......'ckOOOOOOOOOOOOOOOOOOkdool'    .,,,;cllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    cOOOOOOOOo.        ;kOOOOOOOOOOOOOOOOOOxlccc.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    :dxxxkOOOx:,,,,,,,,lkOOOOOOOOOOOOOkxxxxolccc.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    ,ccclxOOOOOOOOOOOOOOOOOOOOOOOOOOOOxocccccccc.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    ,ccclxOOOOOOOOOOOOOOOOOOOOOOOOOOOOkocccccccc.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    ,ccclxOOOOOOOOOOOOOOOOOOOOOOOOOOOOkocccccccc.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    'ccclxOOOOOOOOOOOOOOOOOOOOOOOOOOOOxocccccccc.    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    'ccclxOOOx:,,,,MINT,,,,,;dOOOkddddolcccldxxd,    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    'ccclxOOOo.              cOOOkoccccccccokOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc.    'ccclxOOOd;....CARDS....,oOOOkoccccccccokOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc'    'ccclxOOOOkkkkkkkkkkkkkkkOOOOkoccccccccokOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc'    ':::cdkkkkkkkkkkkkkkkkkkkkkkkxocccclllldkOOk;    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc;;;,.....;ooooooooooooooooooooooollccclxkkkkOOOk;    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllll:.    ,ccccccccccccccccccccccccccccokOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc,....'''',:cccccccccccccc;''';lddddkOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllll:.   .;cccccccccclcc:.   .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllc.   .,:::::::::::::;.   .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllc:::,.                  .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll;.                  .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllc,''''''',''''''    .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc.   .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc.   .oOOOOOOOOOOOOk;    ,lllllllllllllllllllllllllllllll    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MCARD is ERC1155Creator {
    constructor() ERC1155Creator() {}
}