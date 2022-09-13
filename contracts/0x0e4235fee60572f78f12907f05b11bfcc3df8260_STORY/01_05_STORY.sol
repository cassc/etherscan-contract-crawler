// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghoste Stories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0kdolc::;::cclodxk0KNNXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXNNX0Oxl;.   .',,''...   ..':oOXNNXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXNXOdc;,...':ldk0XXXKK0Okxl:'.   .,lkKXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXNXOo;...':odOKNNNXXKKKKKKKKXNNXOdc,....;d0XXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXNKx:. .;lx0XKOxdlc;,''......',coOXNNKkd:'..,l0XXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXNKd,..;dOXXOo:'.                  .;dKNXNXkl,..'l0XXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXNXk;.'lOXNKd;.                         ,dKNXNX0o;..,o0XXXXXXXXXXXXX    //
//    XXXXXXXXXXXXNKo';dKXN0o'                       ..     :OXXXXXKx:'.;kXNXXXXXXXXXX    //
//    XXXXXXXXXXXNXl'lKNXNO;                        ...      .oKNXXXNKx;',l0NXXXXXXXXX    //
//    XXXXXXXXXXXXo'oXNXN0,                         ......     ,kXXXXXXOc'.;ONXXXXXXXX    //
//    XXXXXXXXXXXd.cKNXNK:                           ...'...    .oKNXXXN0:..;0NXXXXXXX    //
//    XXXXXXXXXNk''ONXNKc                            ..:o, .     .lXNXXXN0;..oXXXXXXXX    //
//    XXXXXXXXNK:.oXXXXo.      .::. .                 .,'. .      .xNXXXXNd. 'kNXXXXXX    //
//    XXXXXXXXXo.,0NXXd.     . .ll. .                              :KNXXXNd. .cXNXXXXX    //
//    XXXXXXXN0,.lXXN0,      ..... .                               .kNXXXXo. .;0NXXXXX    //
//    XXXXXXXNk..oXXNd.       ....                                  oNXXNXc...,ONXXXXX    //
//    XXXXXXXNx..oXNX:       ....                                   lXXXN0, ..:0NXXXXX    //
//    XXXXXXXNd..oXN0,       ....                 ..'.              oXXXNd....lKNXXXXX    //
//    XXXXXXXNd. cXN0,                  ...       .;'              .dNXNK:...'dXXXXXXX    //
//    XXXXXXXNx. ,0NXl                   ';'....',;'..             .xNXNx....;ONXXXXXX    //
//    XXXXXXXNk' 'kNNO.                   ...''''......            '0NN0;....cKNXXXXXX    //
//    XXXXXXXN0; .xNXXc                                           .oXNXl....'dXXXXXXXX    //
//    XXXXXXXNXl..oNXNx.                                         .oXXNx.....:0NXXXXXXX    //
//    XXXXXXXXNk' cKNXXl                                        'xXXN0;....,xXXXXXXXXX    //
//    XXXXXXXXNXl..xNXNKc                                     .c0NXNKc.....oXNXXXXXXXX    //
//    XXXXXXXXXN0:.;ONXNKo'                                 .:kXXXXXo.....lKNXXXXXXXXX    //
//    XXXXXXXXXXN0c.;kXXXNKx;.                            .;kXNXXXXx....'oKNXXXXXXXXXX    //
//    XXXXXXXXXXXNKl..lOXXXNXOl,.                       .;xXNXXXXXx,...,xXNXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXx,.'lOXXXXNX0xolc:;,,''......''',:cdOXXXXXNXOl'...c0XXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXX0l..'lOXNNXXXNNNNXXXXKKKKKKKKXXXNNNNXXKOxo:''';lkXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXNXOl,..:ldkO0KKKKKKKKKKKKK00Okkxdoolc:,....,lk0XNXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXX0xo:'.....'',,,'''''......    ......,cx0XNXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXNNXKOkdolc::;,'.............,;cldx0XNNXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXNNNNXXXK00OOOkkkkkOO0KKXNNNXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract STORY is ERC721Creator {
    constructor() ERC721Creator("Ghoste Stories", "STORY") {}
}