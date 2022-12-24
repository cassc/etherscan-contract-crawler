// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OG Christmas Sweater
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                     dddddddd                                  //
//         OOOOOOOOO             GGGGGGGGGGGGG        SSSSSSSSSSSSSSS      tttt                                        d::::::d  iiii                            //
//       OO:::::::::OO        GGG::::::::::::G      SS:::::::::::::::S  ttt:::t                                        d::::::d i::::i                           //
//     OO:::::::::::::OO    GG:::::::::::::::G     S:::::SSSSSS::::::S  t:::::t                                        d::::::d  iiii                            //
//    O:::::::OOO:::::::O  G:::::GGGGGGGG::::G     S:::::S     SSSSSSS  t:::::t                                        d:::::d                                   //
//    O::::::O   O::::::O G:::::G       GGGGGG     S:::::S        ttttttt:::::ttttttt    uuuuuu    uuuuuu      ddddddddd:::::d iiiiiii    ooooooooooo            //
//    O:::::O     O:::::OG:::::G                   S:::::S        t:::::::::::::::::t    u::::u    u::::u    dd::::::::::::::d i:::::i  oo:::::::::::oo          //
//    O:::::O     O:::::OG:::::G                    S::::SSSS     t:::::::::::::::::t    u::::u    u::::u   d::::::::::::::::d  i::::i o:::::::::::::::o         //
//    O:::::O     O:::::OG:::::G    GGGGGGGGGG       SS::::::SSSSStttttt:::::::tttttt    u::::u    u::::u  d:::::::ddddd:::::d  i::::i o:::::ooooo:::::o         //
//    O:::::O     O:::::OG:::::G    G::::::::G         SSS::::::::SS    t:::::t          u::::u    u::::u  d::::::d    d:::::d  i::::i o::::o     o::::o         //
//    O:::::O     O:::::OG:::::G    GGGGG::::G            SSSSSS::::S   t:::::t          u::::u    u::::u  d:::::d     d:::::d  i::::i o::::o     o::::o         //
//    O:::::O     O:::::OG:::::G        G::::G                 S:::::S  t:::::t          u::::u    u::::u  d:::::d     d:::::d  i::::i o::::o     o::::o         //
//    O::::::O   O::::::O G:::::G       G::::G                 S:::::S  t:::::t    ttttttu:::::uuuu:::::u  d:::::d     d:::::d  i::::i o::::o     o::::o         //
//    O:::::::OOO:::::::O  G:::::GGGGGGGG::::G     SSSSSSS     S:::::S  t::::::tttt:::::tu:::::::::::::::uud::::::ddddd::::::ddi::::::io:::::ooooo:::::o         //
//     OO:::::::::::::OO    GG:::::::::::::::G     S::::::SSSSSS:::::S  tt::::::::::::::t u:::::::::::::::u d:::::::::::::::::di::::::io:::::::::::::::o         //
//       OO:::::::::OO        GGG::::::GGG:::G     S:::::::::::::::SS     tt:::::::::::tt  uu::::::::uu:::u  d:::::::::ddd::::di::::::i oo:::::::::::oo          //
//         OOOOOOOOO             GGGGGG   GGGG      SSSSSSSSSSSSSSS         ttttttttttt      uuuuuuuu  uuuu   ddddddddd   dddddiiiiiiii   ooooooooooo            //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OCS is ERC721Creator {
    constructor() ERC721Creator("OG Christmas Sweater", "OCS") {}
}