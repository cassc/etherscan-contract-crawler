// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by OP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                      dddddddd                                                                                               //
//    EEEEEEEEEEEEEEEEEEEEEE            d::::::d  iiii           tttt            iiii                                                          //
//    E::::::::::::::::::::E            d::::::d i::::i       ttt:::t           i::::i                                                         //
//    E::::::::::::::::::::E            d::::::d  iiii        t:::::t            iiii                                                          //
//    EE::::::EEEEEEEEE::::E            d:::::d               t:::::t                                                                          //
//      E:::::E       EEEEEE    ddddddddd:::::d iiiiiii ttttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn        ssssssssss       //
//      E:::::E               dd::::::::::::::d i:::::i t:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    ss::::::::::s      //
//      E::::::EEEEEEEEEE    d::::::::::::::::d  i::::i t:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn ss:::::::::::::s     //
//      E:::::::::::::::E   d:::::::ddddd:::::d  i::::i tttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::ns::::::ssss:::::s    //
//      E:::::::::::::::E   d::::::d    d:::::d  i::::i       t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n s:::::s  ssssss     //
//      E::::::EEEEEEEEEE   d:::::d     d:::::d  i::::i       t:::::t           i::::i o::::o     o::::o  n::::n    n::::n   s::::::s          //
//      E:::::E             d:::::d     d:::::d  i::::i       t:::::t           i::::i o::::o     o::::o  n::::n    n::::n      s::::::s       //
//      E:::::E       EEEEEEd:::::d     d:::::d  i::::i       t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::nssssss   s:::::s     //
//    EE::::::EEEEEEEE:::::Ed::::::ddddd::::::ddi::::::i      t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::ns:::::ssss::::::s    //
//    E::::::::::::::::::::E d:::::::::::::::::di::::::i      tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::ns::::::::::::::s     //
//    E::::::::::::::::::::E  d:::::::::ddd::::di::::::i        tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n s:::::::::::ss      //
//    EEEEEEEEEEEEEEEEEEEEEE   ddddddddd   dddddiiiiiiii          ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  sssssssssss        //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//    bbbbbbbb                                                                                                                                 //
//    b::::::b                                                                                                                                 //
//    b::::::b                                                                                                                                 //
//    b::::::b                                                                                                                                 //
//     b:::::b                                                                                                                                 //
//     b:::::bbbbbbbbb    yyyyyyy           yyyyyyy                                                                                            //
//     b::::::::::::::bb   y:::::y         y:::::y                                                                                             //
//     b::::::::::::::::b   y:::::y       y:::::y                                                                                              //
//     b:::::bbbbb:::::::b   y:::::y     y:::::y                                                                                               //
//     b:::::b    b::::::b    y:::::y   y:::::y                                                                                                //
//     b:::::b     b:::::b     y:::::y y:::::y                                                                                                 //
//     b:::::b     b:::::b      y:::::y:::::y                                                                                                  //
//     b:::::b     b:::::b       y:::::::::y                                                                                                   //
//     b:::::bbbbbb::::::b        y:::::::y                                                                                                    //
//     b::::::::::::::::b          y:::::y                                                                                                     //
//     b:::::::::::::::b          y:::::y                                                                                                      //
//     bbbbbbbbbbbbbbbb          y:::::y                                                                                                       //
//                              y:::::y                                                                                                        //
//                             y:::::y                                                                                                         //
//                            y:::::y                                                                                                          //
//                           y:::::y                                                                                                           //
//                          yyyyyyy                                                                                                            //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//         OOOOOOOOO     PPPPPPPPPPPPPPPPP                                                                                                     //
//       OO:::::::::OO   P::::::::::::::::P                                                                                                    //
//     OO:::::::::::::OO P::::::PPPPPP:::::P                                                                                                   //
//    O:::::::OOO:::::::OPP:::::P     P:::::P                                                                                                  //
//    O::::::O   O::::::O  P::::P     P:::::P                                                                                                  //
//    O:::::O     O:::::O  P::::P     P:::::P                                                                                                  //
//    O:::::O     O:::::O  P::::PPPPPP:::::P                                                                                                   //
//    O:::::O     O:::::O  P:::::::::::::PP                                                                                                    //
//    O:::::O     O:::::O  P::::PPPPPPPPP                                                                                                      //
//    O:::::O     O:::::O  P::::P                                                                                                              //
//    O:::::O     O:::::O  P::::P                                                                                                              //
//    O::::::O   O::::::O  P::::P                                                                                                              //
//    O:::::::OOO:::::::OPP::::::PP                                                                                                            //
//     OO:::::::::::::OO P::::::::P                                                                                                            //
//       OO:::::::::OO   P::::::::P                                                                                                            //
//         OOOOOOOOO     PPPPPPPPPP                                                                                                            //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EOP is ERC1155Creator {
    constructor() ERC1155Creator("Editions by OP", "EOP") {}
}