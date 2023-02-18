// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: something notable
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    NNNNNNNNXXXXXXXNXXKKXNXKKkkKNNNNNNNNNNNNNNNNNNNNNNNNXNNXXNWNNNNNNNWNNNNNNNNWNNNNNNXNNNXKO0XXKXX0OXNNNNNNNNNNNNNNNNNWWNNN    //
//    NNXKXXXNXXXNNNNNNXXNNNNNNXXNNNNNNNNNNNNWNNNNNNNNNNXKKXNNNNNXXNNNNNNNNNNNNNNNNNXNNNNNNNNXKXXKKXNNNWNNNNNNNNXNNXXXNNNNNNNN    //
//    NNXXXK0Ox0XXKKNNNNNNNNNNNNNNNNNXXNNNNNXNNNWNNXNNNNK00KXNNXKKKKXNK0XNNNNNNXXXKOkk0KKXNNNNWNNXKOOXNNNNNNNNNXXX00KXNNNNNNNN    //
//    NNNNK00Ox0XXXNNNNNNNNNNNNNNNXXNNNNNNNNXXNNNNNXXKXNNNNNNNNXXNNXXNX0KWNNNNNNNNNXXXXXXNNXXXNX0KNNXNNNNXXXNNNNX0OO0NNNNNNNNN    //
//    NNXKXXXNNNNNXNNNNNNXKXNXKKXXXXNNNNNNNNNNNNWNNNXKXNNNNNNNNNNNNXNNNNNNNNNNNNXNNNNNNWXXNNNNNXXNNNNWNXXNXXNNNNKkkOXNNNNNNNNN    //
//    NNNNNNNNNNNXNNNNNNNXKNWNXKXXXNNNNNNNNXXNNNNNNNNNNNNNNNXNNNWWNNNNNNNNNNNNNXKXNNNNNNKKXNNNNNNNWNNNNNNNNNNNNXXXNNNNNNNNNNNN    //
//    NNNNNNNNNXKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNNNNNNNXXNNX0OkxdddxxkOKXNXKKXNNNNNNNXXXXXNNNNNNNNWNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNKk0XKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKOdc;'..      ...,coxKXXNNNNNNXXNNNNNXXNNNNNNNNNNNNNNNNNNNNNKXNNNNNNNWW    //
//    NNXNNNNNNXKXNXXNNNNNNNNXKXNNNNXNNNNNNX00XNNNNNNKd;.                  .;d0NNNNNNNNNNNNNNNNNNNXNNNXNWNNNNNNNNNXKNNNXXNWNNN    //
//    NNNNNWNNNNNNNNXNNNNNNNNNXNNNNNNNNWWNNKx0NWNNNXx,...'....               .,oKNNNNNNNNNXXNNNNNNNNNXXNWNNNNNNNNNXNNNNXXNNNWW    //
//    NNNNNNNNNNNNNXKXNNNNKKXNNNNNNNNNNNXXK0KXXXNNKc.  ..'',,.                 .;xXNNXKXXXKKNNWNNNNNNNNNWNNNNNNXNWNNNNNWNNNNNW    //
//    NNNNNNNNXOOOk0NNNNNNXXNNXNNNNKkdc:,'...'',cl;.       ...                   .:c;,',',:ccoxOKXNNNNNNNNNNNNNNNWNXXNNNNNNWNN    //
//    NNNNNNNNXkddxKNNNNNNNNNNNN0d:..                            ...  .                    .....;cxKNNNWNNNNNNNNNNNX0XNNNNNNNN    //
//    NNNNNNNNNNNNNNNNXNNNXXNN0o'                               ........            ..      ..... .'l0NWNNNNNNNNNNNNXNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNXx,.                                 ......          ....  ........      .dXNNNNWWNNNWNNXXXXNNNNWN    //
//    NNNWNNNNNNNNNNNNNNNNNXd'..                          ....''',''''... ..... ..      ..  ...       .lKNNNNNNNNNNNNNNNNNNNNN    //
//    NWNNNNNNNNNNNNNNNNNNXd.                ..     ..,:ldkO0KXXXXXXKK0Oxdl:,.. .. ..   ..... ..    ....lKNNNNNNNNNNNNNNNNNNNN    //
//    NWNNNNNNNNNNNNNWNNNNk'           ..        .;ok0XNNXKOkxdxdddxxxkOKXNNKOd:'. ..      ..     ......,xNNNWNNNNNNNNNNNNWNNW    //
//    KXNNWNNNNNNNNNNNNNNXl.                  .;d0XNX0xl:,.. ..,;,,,,....,:lx0NNKxc.              .......lXWNWNNNNNNNNNNNNNNNN    //
//    00XNNNNNNNNNNNNNNNNXc.                .ckXNXOo;.     ...';:::lc'..    ..;oOXN0o,.            ......cKWNNNNNNNNWNNWNNNWNN    //
//    NNNNNNNNXNWNNNXXNNWXl.              .:ONNKd;.   ..;ldkOKKXXXKXK0kxo:'.    .;dKNKd,.          ......:KWNNNNNNNNNNNNNNNXXN    //
//    NNNNNNNNNNNNNNNNNNNNd.             ,kXNKd'   .'lkKNNNKOkddddddxk0KNNXOd:.   .'oKNKl.         ......oXWNNNNXNNNNNNNNNNXNN    //
//    NNNNNNNNNNNNNNNNNXXXk'           .c0NXk,   .;xKNN0xl;...       ..':lxKNXOl.   .;ONXd'        .....'kNWNNNNNNWNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNWNKx:..          .lXNXo.   ,xXNXx:.                  .'ckXNOc.   .dXNk,         .. ..:d0NNNNNNNWNNNNNNNNN    //
//    NNNNNNNNNNWNNWNKo'.            .cKWXl.  .cKNNk;.     .,cloooolc;'.     .:ONXx'   .oXNk,               'o0NNNNNNNNXXNNNNN    //
//    NNNNNNNNNNNNNXk;.              ;0NXo.  .oXNKo.    .:x0NNNNXXXNNNKkl'.   .,xXNO;.  .dNNx.                'xXNNNNNNNNNNNNN    //
//    XXXNNNNNNNNNXd.               .xNNk.   cKWXl.   .;OXNKkoc;,',,;lkKNKd'.  ..oXNO,   ,OWXc.                .oXWNWNNNNNWNNN    //
//    NXXNNNXXNNNNx.                ;KWXc   ,ONNd.   .lKNXx;....      .,xXNO;. . .xNNd.  .oNWk.                 .dNWNNNNNWNNNX    //
//    NNWNNNNNNNW0;..              .lXWO'   cXW0;    ;KWXd.   ...       .dNNk' ...cXW0;.  ;0WK;                  'ONNNNNNNNNNN    //
//    NNNNNWNNNNNx'.               .oNNx.  .oNNk.   .oNWO'    ...        ;0WKc....,0WXc.  ,OWXc                  .dNNNNNNNNNNN    //
//    NNNNNNNNNNNo.                .oNNd.  .oNNx.   .oNNx.               ;0WXc....,OWXc.  ,OWXc                  .oXWNNNNNNXNN    //
//    NNNNNNNNNNNd.                .lXNk.   cXW0,   .:KW0;    .         .oXW0; ...cKWK;   ;0WK:                  .dNNNNNWNXXNX    //
//    NNNNNNNNNNNO'  .              ;KW0;   ,0WXc... .oXNO;.        .. .dXWXl.   'xNNk'  .lXWO,                  'kNNNNNNNKKNN    //
//    NNNNNNNNNNNXo.                .xNNd.  .lXN0;.   .c0NXkl,......,ld0NN0c.   .oXWKc.  'ONNo.                 .lXWNNXXNNXXNN    //
//    XKNNNNNNNNNN0c.                cKWK:   .oXNO;     .ckXNX0OkkOOKNWN0o'    .oKWXo.  .dNNO,                 .:KNNNNNNNNWNNN    //
//    XKNXXXNNNNNNNKo.               .lKNO;   .lKN0c.     .'cdxkOOOOkdo:..   .;kNWXd.. .oXNKc                 .lKNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNk;.              .oXNO;    ,xXNOc.        .......     .,dKNNk:....dXWXl.               .,dXNNNNNNNNNNNNNN    //
//    NNXXNNNNNNNNNNNNXx:.             .c0NKc.   .:kXN0d:'..           ..;lkXNNOc.. .,xXNKc.              .;xKNNNNWNWNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNO;              ,kNXx,.   .;o0NNK0kolc:::cccodk0XNX0d;.  .'o0NNO;               ,ONNWNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNK:               .l0NKx;.    .;ldOKXNNNNNNNNNXKOxl,..  .'o0NNKd'                :KNWNNNNNNNNNNNWNNNNN    //
//    NNNNNNNNNNNNNNNNNNNXl                 .cOXXOl,.     ..';:::cc:::,'..   .'cx0NN0d;'.                cKNNWNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNx.                  .:xKNXOd:'..          ... ..':lkKNNXkl,....               .xNWNWWNNNNNNNNNNNNNXK    //
//    NNNNNNNNNNNNNNNNNNNWXl.                   .'cd0XNXKOxdlc::::ccloodk0KNNX0xl,......               .cKWNNNNNNNNNNNNNNNNNNN    //
//    NNNWNNNNNNNNNNNNNXXNNKc.               .      .,cok0KKNNNNNNNNNNNXK0kdl:'.    ...               .cKNNNNNNNNNNNNNNNNNNNNN    //
//    NNNWNNNNNNWWNNNNNNNNNNXd.                          ..';;::c::::;;,'........   ..               .oKNNNNWNNNNNNNWNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNN0c.                                       .. ......  ...             .:ONNNNNWNNNNNNNNNNNNNNNNNN    //
//    WNNNNXXNNNNNNNNNNNNNNNWNWN0o;.                                  .   .......   .     .     .,oOXNNNNNNNNWNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNN0xl:,........',.                       .....  .. ........';cdOXNWWNNNNNNNNNNNNWNNNNNNNNNWNN    //
//    NNNNNNNWNNNNNNNNNNNNNNNNNNNNNNNNNXK0OOOOo;,:c'.                               .:k0OOOKXNNWNNNNNNNNNNNNNNNWNNNNWNXNNWNWNN    //
//    WWNNNNNNWNNNNNNNNNWNNNNNNNNNNNNNNNWWNNNXl.  .cc'                               :KWNXXNNNWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWN    //
//    NNNNNNNNNNNXNNNNNNNNNNNNNNNNNNNNNNNNNNNK:   ..;c;'.                      ....  ;0WNNWNNNNNNNWNNNNNNNNNNNNNNNNNNNNNWNNWNN    //
//    NNNNWNNNXKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNk,       .;;,'..             ....      ..dNNNNNNNNNNNNXXNNNNNWNNNNNNNWNNWNNNNNNNN    //
//    NNNNNNNXKXNNNNNNNWNNNNNNNNNNNWNNNNWNNNO:.          ..'.....           ....    ..'xXXXNNNNNNNNNNNWNNNWWNNNNNNWNNWNNNNNNNN    //
//    NNNNNNWNXNNNNNNNNNNNNNNNNNNNNNNNNNNN0o'          ..                     ..    .  .:kXNNNNNNNNNWWNNNNNWNNNNWNWNXNNNNNNNNN    //
//    NNNNNNNNNNNNWNNNNWWNXXNNNNNWNNNNNN0o;.        .....                                .cONNWNNNNNNNNNNNNNWWNNWNNNNNNNNNNNNN    //
//    NNNNNNNNNNWNNWWNNNNNNXNNNNNNNNNX0o'           .....                       .......   .'lONNNNNNNNNNNNNNNWNNNWNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNWNNNNNNNNXXN0o'.         .. ..                       ....... ....   .'l0NNWNNNNNNNNNNNNNNNNWNNNNNNNNNN    //
//    NNNNNNNNXKXNNNNNNNNNNXNNNNNX0d,......    . ....                  .........  .......      .l0NNNNWNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNXXXNNNNNXNNNXKXNNN0d,.  ......  ....                      ...............          'l0NWNNNNNNNNWNNNNNNNNNNNNNNN    //
//    NNNNNNNXXXXNNNNNNNNNNNNNN0c.             .....           .            ..   .....    ...     .;ONNNNNNNNNNNNNWWNNNNNNNNNN    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract notables is ERC1155Creator {
    constructor() ERC1155Creator("something notable", "notables") {}
}