// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: debugMeDaddy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                dddddddd                   bbbbbbbb                                                                                                                                                    dddddddd            dddddddd                            //
//                d::::::d                   b::::::b                                                  MMMMMMMM               MMMMMMMM                  DDDDDDDDDDDDD                                    d::::::d            d::::::d                            //
//                d::::::d                   b::::::b                                                  M:::::::M             M:::::::M                  D::::::::::::DDD                                 d::::::d            d::::::d                            //
//                d::::::d                   b::::::b                                                  M::::::::M           M::::::::M                  D:::::::::::::::DD                               d::::::d            d::::::d                            //
//                d:::::d                     b:::::b                                                  M:::::::::M         M:::::::::M                  DDD:::::DDDDD:::::D                              d:::::d             d:::::d                             //
//        ddddddddd:::::d     eeeeeeeeeeee    b:::::bbbbbbbbb    uuuuuu    uuuuuu     ggggggggg   gggggM::::::::::M       M::::::::::M    eeeeeeeeeeee    D:::::D    D:::::D  aaaaaaaaaaaaa      ddddddddd:::::d     ddddddddd:::::dyyyyyyy           yyyyyyy    //
//      dd::::::::::::::d   ee::::::::::::ee  b::::::::::::::bb  u::::u    u::::u    g:::::::::ggg::::gM:::::::::::M     M:::::::::::M  ee::::::::::::ee  D:::::D     D:::::D a::::::::::::a   dd::::::::::::::d   dd::::::::::::::d y:::::y         y:::::y     //
//     d::::::::::::::::d  e::::::eeeee:::::eeb::::::::::::::::b u::::u    u::::u   g:::::::::::::::::gM:::::::M::::M   M::::M:::::::M e::::::eeeee:::::eeD:::::D     D:::::D aaaaaaaaa:::::a d::::::::::::::::d  d::::::::::::::::d  y:::::y       y:::::y      //
//    d:::::::ddddd:::::d e::::::e     e:::::eb:::::bbbbb:::::::bu::::u    u::::u  g::::::ggggg::::::ggM::::::M M::::M M::::M M::::::Me::::::e     e:::::eD:::::D     D:::::D          a::::ad:::::::ddddd:::::d d:::::::ddddd:::::d   y:::::y     y:::::y       //
//    d::::::d    d:::::d e:::::::eeeee::::::eb:::::b    b::::::bu::::u    u::::u  g:::::g     g:::::g M::::::M  M::::M::::M  M::::::Me:::::::eeeee::::::eD:::::D     D:::::D   aaaaaaa:::::ad::::::d    d:::::d d::::::d    d:::::d    y:::::y   y:::::y        //
//    d:::::d     d:::::d e:::::::::::::::::e b:::::b     b:::::bu::::u    u::::u  g:::::g     g:::::g M::::::M   M:::::::M   M::::::Me:::::::::::::::::e D:::::D     D:::::D aa::::::::::::ad:::::d     d:::::d d:::::d     d:::::d     y:::::y y:::::y         //
//    d:::::d     d:::::d e::::::eeeeeeeeeee  b:::::b     b:::::bu::::u    u::::u  g:::::g     g:::::g M::::::M    M:::::M    M::::::Me::::::eeeeeeeeeee  D:::::D     D:::::Da::::aaaa::::::ad:::::d     d:::::d d:::::d     d:::::d      y:::::y:::::y          //
//    d:::::d     d:::::d e:::::::e           b:::::b     b:::::bu:::::uuuu:::::u  g::::::g    g:::::g M::::::M     MMMMM     M::::::Me:::::::e           D:::::D    D:::::Da::::a    a:::::ad:::::d     d:::::d d:::::d     d:::::d       y:::::::::y           //
//    d::::::ddddd::::::dde::::::::e          b:::::bbbbbb::::::bu:::::::::::::::uug:::::::ggggg:::::g M::::::M               M::::::Me::::::::e        DDD:::::DDDDD:::::D a::::a    a:::::ad::::::ddddd::::::ddd::::::ddddd::::::dd       y:::::::y            //
//     d:::::::::::::::::d e::::::::eeeeeeee  b::::::::::::::::b  u:::::::::::::::u g::::::::::::::::g M::::::M               M::::::M e::::::::eeeeeeeeD:::::::::::::::DD  a:::::aaaa::::::a d:::::::::::::::::d d:::::::::::::::::d        y:::::y             //
//      d:::::::::ddd::::d  ee:::::::::::::e  b:::::::::::::::b    uu::::::::uu:::u  gg::::::::::::::g M::::::M               M::::::M  ee:::::::::::::eD::::::::::::DDD     a::::::::::aa:::a d:::::::::ddd::::d  d:::::::::ddd::::d       y:::::y              //
//       ddddddddd   ddddd    eeeeeeeeeeeeee  bbbbbbbbbbbbbbbb       uuuuuuuu  uuuu    gggggggg::::::g MMMMMMMM               MMMMMMMM    eeeeeeeeeeeeeeDDDDDDDDDDDDD         aaaaaaaaaa  aaaa  ddddddddd   ddddd   ddddddddd   ddddd      y:::::y               //
//                                                                                             g:::::g                                                                                                                                    y:::::y                //
//                                                                                 gggggg      g:::::g                                                                                                                                   y:::::y                 //
//                                                                                 g:::::gg   gg:::::g                                                                                                                                  y:::::y                  //
//                                                                                  g::::::ggg:::::::g                                                                                                                                 y:::::y                   //
//                                                                                   gg:::::::::::::g                                                                                                                                 yyyyyyy                    //
//                                                                                     ggg::::::ggg                                                                                                                                                              //
//                                                                                        gggggg                                                                                                                                                                 //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DMD is ERC721Creator {
    constructor() ERC721Creator("debugMeDaddy", "DMD") {}
}