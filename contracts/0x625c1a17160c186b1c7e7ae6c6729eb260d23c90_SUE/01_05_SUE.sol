// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soul Extraction
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//               ...                 ...                        //
//       ................................                       //
//    ..................................................        //
//    ..,c:;cc,................................':c:;c:..        //
//    .,lxkOKKOd;'...........................,cx0K0kkd;.        //
//    .;dkOKNKkdl::c:.......'coooc'......;oc::ld0XX0Okc.        //
//    ..:x0XX0dlclxOo,......:O0xOk:.....'ckOdcld0NNKOd,.        //
//    ..;d0XNKkdoox0Od:,''',cOK00k:''',:oOKOdookKNNXkc'.        //
//    ..':xKXX Soul XKOxxxk0XK0KX Extraction xoodOXNX0l,..      //
//    ....,:oO0kxdoldO00KXXNKkxxxkKX0K000kdooxOKKxl;'...        //
//    .......;d00kdoooddOO0NOl:c:o0N0OkxddoodOKOl,......        //
//    ........':ldkkkkOKK00K0o:::dKK0KKKOkkkdlc,........        //
//    ...........,ck00KKOxdO0o:;:d0kdxOKXKOo;'..........        //
//    ...........':kXXOd:,:kkl:;:oOd;,:o0NKd:'..........        //
//    ...........';oKXxl:,cx 3DNinjah dd;,;oOX0xc'..........    //
//     ...   ....';o0Kxc;'ckllOKk:ox:':d0X0dc'.........         //
//      .    ....';l0Xkl;':xocOX0oxx:';oOXOdc'....  ...         //
//           ....';lOKOl;',ldoONKkko,';lOXOo:'...  .  .         //
//         .......:o0Xkl,'':k0KNXXOc'';oOXOo:'..     ...        //
//         .. ....:o0Kxc,'':kKXNXXO:'';d0KOl;...      .         //
//            ....;dKXkl;'':k0KXXKd,'';oOX0l,...                //
//            ....;o0Kxl,'.'o0KKXO:''';oOXkc,...                //
//            ....:d0Kxo;...:kKXXx;...,lkKxc,...                //
//             ...:x0KOo;...;xKK0o,...,lOXkc,...                //
//             ...:kKXOo,...,dOOd,....,lOXkl;...                //
//             ...:xKXkl,....;cc;.....,lOX0o;...                //
//             ...:dKXko;.............,oOX0d;...                //
//             ...:d0Kko,.............,oOX0o;...                //
//             ...:kXXOo,.............;d0X0d:...                //
//            ....:kKXOo,.............;d0X0x:...                //
//            ....:xKX0d;............';d0X0d:...                //
//            ...':d0X0d;,,,,,,,,,'',,:d0X0d:....               //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract SUE is ERC1155Creator {
    constructor() ERC1155Creator("Soul Extraction", "SUE") {}
}