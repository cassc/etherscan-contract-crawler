// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gemma.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                   '                 '            //
//           '         '      '      '        '     //
//              '        \    '    /       '        //
//                  ' .   .-"```"-.  . '            //
//                        \`-._.-`/                 //
//             - -  =      \\ | //      =  -  -     //
//                        ' \\|// '                 //
//                  . '      \|/     ' .            //
//               .         '  `  '         .        //
//            .          /    .    \           .    //
//                     .      .      .              //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract gem is ERC1155Creator {
    constructor() ERC1155Creator("gemma.", "gem") {}
}