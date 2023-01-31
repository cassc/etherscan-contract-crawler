// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lucky Shots
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                       //
//    LLLLLLLLLLL                                                   kkkkkkkk                                            SSSSSSSSSSSSSSS hhhhhhh                                       tttt                               //
//    L:::::::::L                                                   k::::::k                                          SS:::::::::::::::Sh:::::h                                    ttt:::t                               //
//    L:::::::::L                                                   k::::::k                                         S:::::SSSSSS::::::Sh:::::h                                    t:::::t                               //
//    LL:::::::LL                                                   k::::::k                                         S:::::S     SSSSSSSh:::::h                                    t:::::t                               //
//      L:::::L               uuuuuu    uuuuuu      cccccccccccccccc k:::::k    kkkkkkkyyyyyyy           yyyyyyy     S:::::S             h::::h hhhhh          ooooooooooo   ttttttt:::::ttttttt        ssssssssss       //
//      L:::::L               u::::u    u::::u    cc:::::::::::::::c k:::::k   k:::::k  y:::::y         y:::::y      S:::::S             h::::hh:::::hhh     oo:::::::::::oo t:::::::::::::::::t      ss::::::::::s      //
//      L:::::L               u::::u    u::::u   c:::::::::::::::::c k:::::k  k:::::k    y:::::y       y:::::y        S::::SSSS          h::::::::::::::hh  o:::::::::::::::ot:::::::::::::::::t    ss:::::::::::::s     //
//      L:::::L               u::::u    u::::u  c:::::::cccccc:::::c k:::::k k:::::k      y:::::y     y:::::y          SS::::::SSSSS     h:::::::hhh::::::h o:::::ooooo:::::otttttt:::::::tttttt    s::::::ssss:::::s    //
//      L:::::L               u::::u    u::::u  c::::::c     ccccccc k::::::k:::::k        y:::::y   y:::::y             SSS::::::::SS   h::::::h   h::::::ho::::o     o::::o      t:::::t           s:::::s  ssssss     //
//      L:::::L               u::::u    u::::u  c:::::c              k:::::::::::k          y:::::y y:::::y                 SSSSSS::::S  h:::::h     h:::::ho::::o     o::::o      t:::::t             s::::::s          //
//      L:::::L               u::::u    u::::u  c:::::c              k:::::::::::k           y:::::y:::::y                       S:::::S h:::::h     h:::::ho::::o     o::::o      t:::::t                s::::::s       //
//      L:::::L         LLLLLLu:::::uuuu:::::u  c::::::c     ccccccc k::::::k:::::k           y:::::::::y                        S:::::S h:::::h     h:::::ho::::o     o::::o      t:::::t    ttttttssssss   s:::::s     //
//    LL:::::::LLLLLLLLL:::::Lu:::::::::::::::uuc:::::::cccccc:::::ck::::::k k:::::k           y:::::::y             SSSSSSS     S:::::S h:::::h     h:::::ho:::::ooooo:::::o      t::::::tttt:::::ts:::::ssss::::::s    //
//    L::::::::::::::::::::::L u:::::::::::::::u c:::::::::::::::::ck::::::k  k:::::k           y:::::y              S::::::SSSSSS:::::S h:::::h     h:::::ho:::::::::::::::o      tt::::::::::::::ts::::::::::::::s     //
//    L::::::::::::::::::::::L  uu::::::::uu:::u  cc:::::::::::::::ck::::::k   k:::::k         y:::::y               S:::::::::::::::SS  h:::::h     h:::::h oo:::::::::::oo         tt:::::::::::tt s:::::::::::ss      //
//    LLLLLLLLLLLLLLLLLLLLLLLL    uuuuuuuu  uuuu    cccccccccccccccckkkkkkkk    kkkkkkk       y:::::y                 SSSSSSSSSSSSSSS    hhhhhhh     hhhhhhh   ooooooooooo             ttttttttttt    sssssssssss        //
//                                                                                           y:::::y                                                                                                                     //
//                                                                                          y:::::y                                                                                                                      //
//                                                                                         y:::::y                                                                                                                       //
//                                                                                        y:::::y                                                                                                                        //
//                                                                                       yyyyyyy                                                                                                                         //
//                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LUCKY is ERC1155Creator {
    constructor() ERC1155Creator("Lucky Shots", "LUCKY") {}
}