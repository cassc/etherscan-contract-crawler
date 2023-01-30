// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: konoka
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                   ..&g-, .,      ....(J+J(-...                             //
//               (JdMMMMMMMNMNN.+MMMMMMMMMMMMMMMMMMNa.,                       //
//              .gQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN,                    //
//             .MMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMe...               //
//            .MMMMMMMMMNQHNHNMNHMMNkMMMMMMMMMMMMMMMMMMMMMMMMNMMMMNa,         //
//           .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMHNM#MMMMMMMMMMMMMMMMMMN,       //
//            [email protected]=     //
//           ~/"dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMNNMN,     //
//              -MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMb     //
//               (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF     //
//               .GMMMMMMMMMMMMMMMMMNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN`     //
//               ,JMMMMMMMMMMM#MMMM#(#vMMMMMWMMMMMMdMMMMMMMMMMMMMMMMMTM.      //
//               _dMMMMMMMMMM?57"""!(3(7"T9YdMMMM#[email protected]",^      //
//                JMMMMMNMF.._(gMMMMQ,..........__-HdMMM#MMMMMMMMMD'          //
//            `    WdMMMNM%--"~J .MMb?!........._((J./7"(#MMMMMMM#            //
//                 .3MMMMM_. `.MMMMMM ........._1?4NNWN-.(TMMMMMMF            //
//                 ..dMMM#.._`,N9TBMt..........(MaMMd]([email protected]             //
//                  _dMMd#..~~_-<~~_...........,MMMMN}`(3(MMMMMD              //
//            `      JMMd#.~~~:::~~............~_~(dY` ..JMMMF`               //
//                     .H....~.................~~:__~...(MMM#                 //
//                       !-............_........~_~::~~_MMMM'                 //
//                        .m,...........~............._?MMM'          `       //
//            `            .dvJ............~........_                         //
//                   `       \j ~~.............._`                `           //
//               `     `        .~~~~~~~.~.~-=(                 .             //
//            `   ..(::::_-     ``[email protected]     ..ggNgJ,   ` JM!   .,  `    //
//               (::::::::~     `    ``JM9^  `  ([email protected]^.M# ?MN..HMMM""MNJMN.     //
//              (::::::::~   `     .g[         JM'  JM^::(M]  .M]  ,M).H#     //
//           ` (::::::::`     `    M#          MN..MM' <+MM<<[email protected]   (M!        //
//             :::::::~    `   `   (YMMMMMMMMt .TMY= .NMM8::([email protected]         //
//            .::::::~   `  `  ` `  ` `` `  `            <:::::<              //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract konoka is ERC1155Creator {
    constructor() ERC1155Creator("konoka", "konoka") {}
}