// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZON-Verse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//    ZZZZZZZZZZZZZZZZZZZ                                                                                                                                      //
//    Z:::::::::::::::::Z                                                                                                                                      //
//    Z:::::::::::::::::Z                                                                                                                                      //
//    Z:::ZZZZZZZZ:::::Z                                                                                                                                       //
//    ZZZZZ     Z:::::Z      eeeeeeeeeeee  xxxxxxx      xxxxxxx ooooooooooo   nnnn  nnnnnnnn                                                                   //
//            Z:::::Z      ee::::::::::::ee x:::::x    x:::::xoo:::::::::::oo n:::nn::::::::nn                                                                 //
//           Z:::::Z      e::::::eeeee:::::eex:::::x  x:::::xo:::::::::::::::on::::::::::::::nn                                                                //
//          Z:::::Z      e::::::e     e:::::e x:::::xx:::::x o:::::ooooo:::::onn:::::::::::::::n                                                               //
//         Z:::::Z       e:::::::eeeee::::::e  x::::::::::x  o::::o     o::::o  n:::::nnnn:::::n                                                               //
//        Z:::::Z        e:::::::::::::::::e    x::::::::x   o::::o     o::::o  n::::n    n::::n                                                               //
//       Z:::::Z         e::::::eeeeeeeeeee     x::::::::x   o::::o     o::::o  n::::n    n::::n                                                               //
//    ZZZ:::::Z     ZZZZZe:::::::e             x::::::::::x  o::::o     o::::o  n::::n    n::::n                                                               //
//    Z::::::ZZZZZZZZ:::Ze::::::::e           x:::::xx:::::x o:::::ooooo:::::o  n::::n    n::::n                                                               //
//    Z:::::::::::::::::Z e::::::::eeeeeeee  x:::::x  x:::::xo:::::::::::::::o  n::::n    n::::n                                                               //
//    Z:::::::::::::::::Z  ee:::::::::::::e x:::::x    x:::::xoo:::::::::::oo   n::::n    n::::n                                                               //
//    ZZZZZZZZZZZZZZZZZZZ    eeeeeeeeeeeeeexxxxxxx      xxxxxxx ooooooooooo     nnnnnn    nnnnnn                                                               //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//         OOOOOOOOO                                                                                                                                           //
//       OO:::::::::OO                                                                                                                                         //
//     OO:::::::::::::OO                                                                                                                                       //
//    O:::::::OOO:::::::O                                                                                                                                      //
//    O::::::O   O::::::O   mmmmmmm    mmmmmmm       eeeeeeeeeeee       ggggggggg   ggggg aaaaaaaaaaaaa                                                        //
//    O:::::O     O:::::O mm:::::::m  m:::::::mm   ee::::::::::::ee    g:::::::::ggg::::g a::::::::::::a                                                       //
//    O:::::O     O:::::Om::::::::::mm::::::::::m e::::::eeeee:::::ee g:::::::::::::::::g aaaaaaaaa:::::a                                                      //
//    O:::::O     O:::::Om::::::::::::::::::::::me::::::e     e:::::eg::::::ggggg::::::gg          a::::a                                                      //
//    O:::::O     O:::::Om:::::mmm::::::mmm:::::me:::::::eeeee::::::eg:::::g     g:::::g    aaaaaaa:::::a                                                      //
//    O:::::O     O:::::Om::::m   m::::m   m::::me:::::::::::::::::e g:::::g     g:::::g  aa::::::::::::a                                                      //
//    O:::::O     O:::::Om::::m   m::::m   m::::me::::::eeeeeeeeeee  g:::::g     g:::::g a::::aaaa::::::a                                                      //
//    O::::::O   O::::::Om::::m   m::::m   m::::me:::::::e           g::::::g    g:::::ga::::a    a:::::a                                                      //
//    O:::::::OOO:::::::Om::::m   m::::m   m::::me::::::::e          g:::::::ggggg:::::ga::::a    a:::::a                                                      //
//     OO:::::::::::::OO m::::m   m::::m   m::::m e::::::::eeeeeeee   g::::::::::::::::ga:::::aaaa::::::a                                                      //
//       OO:::::::::OO   m::::m   m::::m   m::::m  ee:::::::::::::e    gg::::::::::::::g a::::::::::aa:::a                                                     //
//         OOOOOOOOO     mmmmmm   mmmmmm   mmmmmm    eeeeeeeeeeeeee      gggggggg::::::g  aaaaaaaaaa  aaaa                                                     //
//                                                                               g:::::g                                                                       //
//                                                                   gggggg      g:::::g                                                                       //
//                                                                   g:::::gg   gg:::::g                                                                       //
//                                                                    g::::::ggg:::::::g                                                                       //
//                                                                     gg:::::::::::::g                                                                        //
//                                                                       ggg::::::ggg                                                                          //
//                                                                          gggggg                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//    NNNNNNNN        NNNNNNNN                                                                  tttt                            kkkkkkkk             iiii      //
//    N:::::::N       N::::::N                                                               ttt:::t                            k::::::k            i::::i     //
//    N::::::::N      N::::::N                                                               t:::::t                            k::::::k             iiii      //
//    N:::::::::N     N::::::N                                                               t:::::t                            k::::::k                       //
//    N::::::::::N    N::::::N    eeeeeeeeeeee    rrrrr   rrrrrrrrr      ooooooooooo   ttttttt:::::ttttttt      aaaaaaaaaaaaa    k:::::k    kkkkkkkiiiiiii     //
//    N:::::::::::N   N::::::N  ee::::::::::::ee  r::::rrr:::::::::r   oo:::::::::::oo t:::::::::::::::::t      a::::::::::::a   k:::::k   k:::::k i:::::i     //
//    N:::::::N::::N  N::::::N e::::::eeeee:::::eer:::::::::::::::::r o:::::::::::::::ot:::::::::::::::::t      aaaaaaaaa:::::a  k:::::k  k:::::k   i::::i     //
//    N::::::N N::::N N::::::Ne::::::e     e:::::err::::::rrrrr::::::ro:::::ooooo:::::otttttt:::::::tttttt               a::::a  k:::::k k:::::k    i::::i     //
//    N::::::N  N::::N:::::::Ne:::::::eeeee::::::e r:::::r     r:::::ro::::o     o::::o      t:::::t              aaaaaaa:::::a  k::::::k:::::k     i::::i     //
//    N::::::N   N:::::::::::Ne:::::::::::::::::e  r:::::r     rrrrrrro::::o     o::::o      t:::::t            aa::::::::::::a  k:::::::::::k      i::::i     //
//    N::::::N    N::::::::::Ne::::::eeeeeeeeeee   r:::::r            o::::o     o::::o      t:::::t           a::::aaaa::::::a  k:::::::::::k      i::::i     //
//    N::::::N     N:::::::::Ne:::::::e            r:::::r            o::::o     o::::o      t:::::t    tttttta::::a    a:::::a  k::::::k:::::k     i::::i     //
//    N::::::N      N::::::::Ne::::::::e           r:::::r            o:::::ooooo:::::o      t::::::tttt:::::ta::::a    a:::::a k::::::k k:::::k   i::::::i    //
//    N::::::N       N:::::::N e::::::::eeeeeeee   r:::::r            o:::::::::::::::o      tt::::::::::::::ta:::::aaaa::::::a k::::::k  k:::::k  i::::::i    //
//    N::::::N        N::::::N  ee:::::::::::::e   r:::::r             oo:::::::::::oo         tt:::::::::::tt a::::::::::aa:::ak::::::k   k:::::k i::::::i    //
//    NNNNNNNN         NNNNNNN    eeeeeeeeeeeeee   rrrrrrr               ooooooooooo             ttttttttttt    aaaaaaaaaa  aaaakkkkkkkk    kkkkkkkiiiiiiii    //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZON is ERC721Creator {
    constructor() ERC721Creator("ZON-Verse", "ZON") {}
}