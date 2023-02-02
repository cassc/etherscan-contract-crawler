// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shiffu
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//       SSSSSSSSSSSSSSS hhhhhhh               iiii     ffffffffffffffff    ffffffffffffffff                        //
//     SS:::::::::::::::Sh:::::h              i::::i   f::::::::::::::::f  f::::::::::::::::f                       //
//    S:::::SSSSSS::::::Sh:::::h               iiii   f::::::::::::::::::ff::::::::::::::::::f                      //
//    S:::::S     SSSSSSSh:::::h                      f::::::fffffff:::::ff::::::fffffff:::::f                      //
//    S:::::S             h::::h hhhhh       iiiiiii  f:::::f       fffffff:::::f       ffffffuuuuuu    uuuuuu      //
//    S:::::S             h::::hh:::::hhh    i:::::i  f:::::f             f:::::f             u::::u    u::::u      //
//     S::::SSSS          h::::::::::::::hh   i::::i f:::::::ffffff      f:::::::ffffff       u::::u    u::::u      //
//      SS::::::SSSSS     h:::::::hhh::::::h  i::::i f::::::::::::f      f::::::::::::f       u::::u    u::::u      //
//        SSS::::::::SS   h::::::h   h::::::h i::::i f::::::::::::f      f::::::::::::f       u::::u    u::::u      //
//           SSSSSS::::S  h:::::h     h:::::h i::::i f:::::::ffffff      f:::::::ffffff       u::::u    u::::u      //
//                S:::::S h:::::h     h:::::h i::::i  f:::::f             f:::::f             u::::u    u::::u      //
//                S:::::S h:::::h     h:::::h i::::i  f:::::f             f:::::f             u:::::uuuu:::::u      //
//    SSSSSSS     S:::::S h:::::h     h:::::hi::::::if:::::::f           f:::::::f            u:::::::::::::::uu    //
//    S::::::SSSSSS:::::S h:::::h     h:::::hi::::::if:::::::f           f:::::::f             u:::::::::::::::u    //
//    S:::::::::::::::SS  h:::::h     h:::::hi::::::if:::::::f           f:::::::f              uu::::::::uu:::u    //
//     SSSSSSSSSSSSSSS    hhhhhhh     hhhhhhhiiiiiiiifffffffff           fffffffff                uuuuuuuu  uuuu    //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHF is ERC1155Creator {
    constructor() ERC1155Creator("Shiffu", "SHF") {}
}