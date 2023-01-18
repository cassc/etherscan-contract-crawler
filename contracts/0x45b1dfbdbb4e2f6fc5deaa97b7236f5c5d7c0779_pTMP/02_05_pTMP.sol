// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pT Mint Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//                                                                              //
//               _______   __  __  _         _     _____                        //
//              |__   __| |  \/  |(_)       | |   |  __ \                       //
//           _ __  | |    | \  / | _  _ __  | |_  | |__) |__ _  ___  ___        //
//          | '_ \ | |    | |\/| || || '_ \ | __| |  ___// _` |/ __|/ __|       //
//          | |_) || |    | |  | || || | | || |_  | |   | (_| |\__ \\__ \       //
//          | .__/ |_|    |_|  |_||_||_| |_| \__| |_|    \__,_||___/|___/       //
//          | |                                                                 //
//          |_|                                                                 //
//                                                                              //
//                                                                              //
//                         ............................                         //
//                        .dXXXXXXXXXXXXXXXXXXXXXXXXXXO,                        //
//                      ,xd:,,,,,,,,,,,,,,,,,,,,,,,,,;;lxc.                     //
//                   .;:ldl.                           ;doc:.                   //
//                   ;XWc                                '0Mo                   //
//                   ;XWc                                '0Mo                   //
//                   ;XWc                                '0Mo                   //
//                   ;XWc    .,;;;;;;;;;;;;;;;;;;;;;;;;;;oXMO:;;;;;;.           //
//                   ;XWc   .;OXKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXWMx.          //
//                   ;XWc .oKd'..................................;0Mx.          //
//                   ;XW0dxXMXxooooooooo;.    .:oooooooooooooooooxXMx.          //
//                   .dkKMW0xkxxxxxxxxxxl;;,,,:oxxxxxxxxxONMXkxxxxxx:           //
//                     .lXO'            ;k0XNW0'         'ONo.                  //
//                   'kOc..              ..'xM0'          ..cOk,                //
//                   ;XWc       .lc.        'cclo;     ,o;. :NN:                //
//                   ;XWc       cNX;        .':0MO:'. .xMO. :NN:                //
//                   ;XWc       cNX;       .oWWNNNWNl .kMO. :NN:                //
//                   ;XWc       cWX;    'dxOXMXc'lXMXO0NMO. :NN:                //
//                   ;XWc       cNX;    :0NWOlllllllllllllllkWN:                //
//                   'xOc'.     ,kx'    :0NNc .kMx. ...  '0MX0k,                //
//                      lN0,            :0NN: .kMx. :X0, '0Wd.                  //
//                      lWW0kc.      .ok0NWNc .kMx. .,'   ',cxx'                //
//                      lWNkolccccccccloONWNc .kMx. .c:.    :NN:                //
//                      :Ok;.:k000000d. :0NN: .kMO,.dWX;    :NN:                //
//                       ..xXx.......   :0NN: .kMWXXNMX;    :NN:                //
//                        .kMXkx;       :0NN: .kM0c;kWW0xc. :NN:                //
//                        .kMXxdl:;.    :0NN: .kM0l:kWNOdoc:coo.                //
//                        .kMk. ;0O,  ..:kO0; .kMNKKKKk' .xKc                   //
//                        .kMk.  ..  .xXo'..  .kMk'....   ..                    //
//                        .kMk.       ,:codo' .kMx.                             //
//                        .kMk.         :0NWx;lKMx.                             //
//                        .kMk.         :0NMNXXXXo.                             //
//                        .kMk.         :0NNo.....                              //
//                        .kMk.         :0NN:                                   //
//                        .kMk.         :0NN:                                   //
//                                                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract pTMP is ERC721Creator {
    constructor() ERC721Creator("pT Mint Pass", "pTMP") {}
}