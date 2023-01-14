// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SKRPTD Graffiti
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                             __    _                                         //
//                        _wr""        "-q__                                   //
//                     _dP                 9m_                                 //
//                   _#P                     9#_                               //
//                  d#@                       9#m                              //
//                 d##                         ###                             //
//                J###                         ###L                            //
//                {###K                       J###K                            //
//                ]####K      ___aaa___      J####F                            //
//            __gmM######_  w#P""   ""9#m  _d#####Mmw__                        //
//         _g##############mZ_         __g##############m_                     //
//       _d####[email protected]@@M#######Mmp gm#########@@[email protected]####m_                   //
//      a###""          ,Z"#####@" '######"\g          ""M##m                  //
//     J#@"             0L  "*##     ##@"  J#              *#K                 //
//     #"               `#    "_gmwgm_~    dF               `#_                //
//    7F                 "#_   ]#####F   _dK                 JE                //
//    ]                    *m__ ##### [email protected]"                   F                //
//                           "PJ#####LP"                                       //
//     `                       0######_                      '                 //
//                           _0########_                                       //
//         .               _d#####^#####m__              ,                     //
//          "*w_________am#####P"   ~9#####mw_________w*"                      //
//              ""[email protected]#####@M""           ""[email protected]#####@M""                          //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract SKRPT is ERC721Creator {
    constructor() ERC721Creator("SKRPTD Graffiti", "SKRPT") {}
}