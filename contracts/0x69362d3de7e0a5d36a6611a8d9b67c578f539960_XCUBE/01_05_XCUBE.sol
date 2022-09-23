// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: xcube
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                          bbbbbbbb                                    //
//                                                          b::::::b                                    //
//                                                          b::::::b                                    //
//                                                          b::::::b                                    //
//                                                           b:::::b                                    //
//    xxxxxxx      xxxxxxx ccccccccccccccccuuuuuu    uuuuuu  b:::::bbbbbbbbb        eeeeeeeeeeee        //
//     x:::::x    x:::::xcc:::::::::::::::cu::::u    u::::u  b::::::::::::::bb    ee::::::::::::ee      //
//      x:::::x  x:::::xc:::::::::::::::::cu::::u    u::::u  b::::::::::::::::b  e::::::eeeee:::::ee    //
//       x:::::xx:::::xc:::::::cccccc:::::cu::::u    u::::u  b:::::bbbbb:::::::be::::::e     e:::::e    //
//        x::::::::::x c::::::c     cccccccu::::u    u::::u  b:::::b    b::::::be:::::::eeeee::::::e    //
//         x::::::::x  c:::::c             u::::u    u::::u  b:::::b     b:::::be:::::::::::::::::e     //
//         x::::::::x  c:::::c             u::::u    u::::u  b:::::b     b:::::be::::::eeeeeeeeeee      //
//        x::::::::::x c::::::c     cccccccu:::::uuuu:::::u  b:::::b     b:::::be:::::::e               //
//       x:::::xx:::::xc:::::::cccccc:::::cu:::::::::::::::uub:::::bbbbbb::::::be::::::::e              //
//      x:::::x  x:::::xc:::::::::::::::::c u:::::::::::::::ub::::::::::::::::b  e::::::::eeeeeeee      //
//     x:::::x    x:::::xcc:::::::::::::::c  uu::::::::uu:::ub:::::::::::::::b    ee:::::::::::::e      //
//    xxxxxxx      xxxxxxx cccccccccccccccc    uuuuuuuu  uuuubbbbbbbbbbbbbbbb       eeeeeeeeeeeeee      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XCUBE is ERC721Creator {
    constructor() ERC721Creator("xcube", "XCUBE") {}
}