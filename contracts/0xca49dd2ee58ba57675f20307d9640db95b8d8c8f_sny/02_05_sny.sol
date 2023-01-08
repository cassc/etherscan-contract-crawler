// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sunny
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
//    LLLLLLLLLLL               iiii                     hhhhhhh                     tttt                                  SSSSSSSSSSSSSSS hhhhhhh                                      tttt              //
//    L:::::::::L              i::::i                    h:::::h                  ttt:::t                                SS:::::::::::::::Sh:::::h                                   ttt:::t              //
//    L:::::::::L               iiii                     h:::::h                  t:::::t                               S:::::SSSSSS::::::Sh:::::h                                   t:::::t              //
//    LL:::::::LL                                        h:::::h                  t:::::t                               S:::::S     SSSSSSSh:::::h                                   t:::::t              //
//      L:::::L               iiiiiii    ggggggggg   gggggh::::h hhhhh      ttttttt:::::tttttttyyyyyyy           yyyyyyyS:::::S             h::::h hhhhh       uuuuuu    uuuuuuttttttt:::::ttttttt        //
//      L:::::L               i:::::i   g:::::::::ggg::::gh::::hh:::::hhh   t:::::::::::::::::t y:::::y         y:::::y S:::::S             h::::hh:::::hhh    u::::u    u::::ut:::::::::::::::::t        //
//      L:::::L                i::::i  g:::::::::::::::::gh::::::::::::::hh t:::::::::::::::::t  y:::::y       y:::::y   S::::SSSS          h::::::::::::::hh  u::::u    u::::ut:::::::::::::::::t        //
//      L:::::L                i::::i g::::::ggggg::::::ggh:::::::hhh::::::htttttt:::::::tttttt   y:::::y     y:::::y     SS::::::SSSSS     h:::::::hhh::::::h u::::u    u::::utttttt:::::::tttttt        //
//      L:::::L                i::::i g:::::g     g:::::g h::::::h   h::::::h     t:::::t          y:::::y   y:::::y        SSS::::::::SS   h::::::h   h::::::hu::::u    u::::u      t:::::t              //
//      L:::::L                i::::i g:::::g     g:::::g h:::::h     h:::::h     t:::::t           y:::::y y:::::y            SSSSSS::::S  h:::::h     h:::::hu::::u    u::::u      t:::::t              //
//      L:::::L                i::::i g:::::g     g:::::g h:::::h     h:::::h     t:::::t            y:::::y:::::y                  S:::::S h:::::h     h:::::hu::::u    u::::u      t:::::t              //
//      L:::::L         LLLLLL i::::i g::::::g    g:::::g h:::::h     h:::::h     t:::::t    tttttt   y:::::::::y                   S:::::S h:::::h     h:::::hu:::::uuuu:::::u      t:::::t    tttttt    //
//    LL:::::::LLLLLLLLL:::::Li::::::ig:::::::ggggg:::::g h:::::h     h:::::h     t::::::tttt:::::t    y:::::::y        SSSSSSS     S:::::S h:::::h     h:::::hu:::::::::::::::uu    t::::::tttt:::::t    //
//    L::::::::::::::::::::::Li::::::i g::::::::::::::::g h:::::h     h:::::h     tt::::::::::::::t     y:::::y         S::::::SSSSSS:::::S h:::::h     h:::::h u:::::::::::::::u    tt::::::::::::::t    //
//    L::::::::::::::::::::::Li::::::i  gg::::::::::::::g h:::::h     h:::::h       tt:::::::::::tt    y:::::y          S:::::::::::::::SS  h:::::h     h:::::h  uu::::::::uu:::u      tt:::::::::::tt    //
//    LLLLLLLLLLLLLLLLLLLLLLLLiiiiiiii    gggggggg::::::g hhhhhhh     hhhhhhh         ttttttttttt     y:::::y            SSSSSSSSSSSSSSS    hhhhhhh     hhhhhhh    uuuuuuuu  uuuu        ttttttttttt      //
//                                                g:::::g                                            y:::::y                                                                                              //
//                                    gggggg      g:::::g                                           y:::::y                                                                                               //
//                                    g:::::gg   gg:::::g                                          y:::::y                                                                                                //
//                                     g::::::ggg:::::::g                                         y:::::y                                                                                                 //
//                                      gg:::::::::::::g                                         yyyyyyy                                                                                                  //
//                                        ggg::::::ggg                                                                                                                                                    //
//                                           gggggg                                                                                                                                                       //
//                                                                                                                                                                                                        //
//                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract sny is ERC721Creator {
    constructor() ERC721Creator("Sunny", "sny") {}
}