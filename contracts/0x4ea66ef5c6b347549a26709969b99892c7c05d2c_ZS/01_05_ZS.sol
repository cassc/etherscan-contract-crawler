// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Z’s 2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                'o:.                                                                                            //
//                               .OWx.                                                                                            //
//                               cNX:                                                                                             //
//                              .kMK;                                                                                             //
//                              cNMWKxooooooooooooooooooooooooooooooooooooooooooooooooolc'                                        //
//                             .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                                      //
//                        .lk; :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                                     //
//                        cNK, lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                                     //
//                       .kWx. ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                      //
//                       :XMk.  ,xKNWWWWWWWWWWWWWWWWWWWMMMMMMMMMMWMMMMMMMMMMMMMMMMWWWWMMMMO'                                      //
//                     .cKMMNx,.  .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;:oXMMMMMMWXOoc:;;;;oKMNl                                       //
//           .:xxxkxxxkKWMMMMMN0kxxxd,                           ..,dNMMMMXkc'        .kM0'                                       //
//            ;llllllokXMMWKxollllllc.                        .,o0XNMMWXkc'           .kKc                                        //
//                     oWNd.                               .,o0NMMMWXkc.               ..                                         //
//                    .dWO.                             .,o0NMMWXkoc.                                                             //
//                    ,0Nl                           .,o0NMMWXkc.                            'lxO0O000000000000000Okl.            //
//                    oW0'                        .,o0NMMWXxc.                             .dNMMMMMMMMMMMMMMMMMMMMMMMk.           //
//                   .cx;                      .,o0NMMWXx:.                         ,dl.   oWMMMMMMMMMMMMMMMMMMMMMMMMk.           //
//                                          .,o0NMMWKx:.                           .OWk.  '0NOlcccccccccccccccccclkWNc            //
//                                       .,o0NMMWKx:.                              cNNc   lNk.                    ;Od.            //
//                                    .,o0NMMWKx:.                                .kMO.  .OWOc;;;;;;;;;;;;;;;;;;;;,.              //
//                                 .,o0NMMWKx:.                                   lNNc    cOKKKKKKKKKKKKKKKKKK00XNXl              //
//                              .,o0WMMMMM0,                                   .'dXMO'    ......................cXWo              //
//                           .,o0NMMMMMMMMNOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0NMMWl   ;kl.                    lNK,              //
//                        .,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'  .kNl                    .OWd.              //
//                     .,o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo   :XNd;;;;;;;;;;;;;;;;;;;:kNK;               //
//                   'o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  .xWMMWWWWWWWWWWWWWWWWWWWWMWx.               //
//                  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo.   .OMMMMMMMMMMMMMMMMMMMMMMMWO'                //
//                  ;0NNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXKkc.      ;OXNNNNWWWWWWWWWWWWWWNXOc.                 //
//                   .''''''''''''''''''''''''''''''''''''''''''''''''''''''..           .'''''''''''''''''''.                    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZS is ERC721Creator {
    constructor() ERC721Creator(unicode"Z’s 2", "ZS") {}
}