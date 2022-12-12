// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wRekt Station
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                                                                              .',..,lxk    //
//                                                                          ....ckKKXX       //
//                                                                .,.      .ldc..:OXXX       //
//                                                              'cc:;.    .cxdoc,.'xKX       //
//                   ....'.....                               .:c'  .,'  .;lcclddc..l0       //
//            ...',,;;;;;::::::;;'.                         .:c.      ';.'c::llcc:.  :       //
//        .',:codxxxxxxxkOOOOkkxdlc:;.                     .:;        ,xkc....               //
//      .::cdO0KXNNNNXK0kkkkkkOOkxdl:c;.               .,:ll;'.     ;x0KXKd.                 //
//     .c:;xXNNXNNNXklcl:;,,,,;::lddlcoc.           .';;cl,...';;';d0XXXKOdc,.               //
//     'c;oXNNNNNNXx;cl,.    .;;;,;loolol,        .';;;,:c.   .ck0KXK0kxoc:cl,               //
//     .::lKNNWNNN0::l'      .lodxdc;:oloo,       '::c:;:;.',;o0K0KKOo,..'..                 //
//      ,c:xNNWWNXk;cl..'''.  :xxxOk:.;lcdo.    ..:dxd:',:lol;;:c:::cl:..                    //
//      .:cckNNNNNk;cl.,:,;cc;'ckOOOx;'cccxl..::;;loc;:::;'..        .col::::;'.             //
//       .c::kXNNNO;;l'.:c;:dk:..lxo;..:l;dOl:llclo:;;;;;;,,'..     .:dkkxl:;:ccc,.          //
//        .:ccdKNNXo,c:.'oxdkOx:.'l:.  .;coOOc....     ....',;;;,.':oOKXXXX0xoc::cl:.        //
//          ':::dXNKo;c, .'lOOkl',ldl.  ..;d0ko;               ..:looxOKXNNNNXKKkoloo:       //
//            ';;cOXXd::,  .::.   .:c:cccdddooxo'                  .':oxkKNNNNNNNNX0kx       //
//              .':oOKklc;.      .';oxdl::cc::col.                    .,lx0XNNWWWWWNNX       //
//                .;:lkOxoc.   .;lxdol'  'lxl:ccol.                     .;dk0NNNWWWWNN       //
//                 .';:lO0xc..;col;'..,::ldl...;:oo,                      ,ood0NNWWNNN       //
//                   .,:lkko:lol;..,:col:,.. .':ldko,                     .co;;dKNWWNN       //
//                     .;ldo:;'. .;oo:'.  ..;cloOKOlc'                 ..';ld:'cONNWWW       //
//                       ,cdkkoc;;::::;;;;coxkO0KXKd;,'''''',,,,,,,,,;;;:cloxk0KNNNNWW       //
//                       .cd0NNNXKOxdllloxO0XNNNXKXXkoodxkkxdooooddolllldOKNNNNNNNNNWW       //
//                       ,:oKNNXXXNWNNXXNNNNNNNNXXNNNNNNNNNNNXXXXXXXXXXNNNWWWWWWWWWWWW       //
//                     .,,:kNNNKKNNNNNNNNNNWNNNNXXNWNNNNWWWWWWWWNNNNNNNNWWWWWWWWWWWWNN       //
//                  ..',,lOXNNXKXNNNNNNNNNWWNNXXNNWWWWNNNNWWWNNNNNWWNNNNNWNWWWNNNNXKOk       //
//                ..,;:oOXNNNNKKNNNNNNWWWWWNXXXNNWWNWWNWWWNNNNNNWNNNNNNNNNNNNX0Okkxo:'       //
//               ':ldOXNNWWNNXXNNNWNNNWWWNKOKNWWWNNNNNWWWNNNNNNWWNNNNNNNX0kdllcc:,'.         //
//             .cxOKNNWWWWNNXXNNNNNNNWWWWNkodkOKNNNNNNWWNNNNNNWWWWNNXKOxol:;;,'.             //
//           .:x0XNWWWWNNNNNNNNNNNNNWWWWWXxoloodxOXNWWWWNNNNNNWNNNNXkoll:,'.                 //
//          'o0XNWWWWWWNNNNNNNNNWWWWWWWWW0do::ldxddk0NWWWNNNNNNWWNXxlol'                     //
//        .:OXNNWWWWWWWNNNNNNNNWWWWWWWWWNkdxdl:lxkxddONWWWWWWWWWWNOooc.                      //
//       .l0XNWWWWNWWWNNNNNNNNNWWWWWWWWWXxdxdoloxkOKXNWWWWWWWWWWNKdoc.                       //
//      .cOXNWWWWWWWWWNNXXNNNNNNNNNWWWWWXkxkO00KNNWWWWWWWWWWWWWWXkol'                        //
//     .:xKNWWWWWWWWWNX0O0XNNNNNNNNNWWWWNNNNNNNNWNNWWWWWWWWWWWWNKdo:                         //
//    .;lkXWWWWWNNWNNNKxx0NNNNNNNNNNNWWWWWNNNNNNNNNNNNNNNNNWWWWN0dl'                         //
//    .;:kNNWWNNNNNNNXkodKNNNNNXXXNNNNNNNNNNNNNNNNNNNNXXXNNNWWWN0dc.                         //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract REKT is ERC721Creator {
    constructor() ERC721Creator("wRekt Station", "REKT") {}
}