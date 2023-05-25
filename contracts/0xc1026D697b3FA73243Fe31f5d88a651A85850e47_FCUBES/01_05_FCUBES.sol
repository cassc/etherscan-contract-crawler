// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 4Cubes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                           bbbbbbbb                                                     //
//           444444444                                       b::::::b                                                     //
//          4::::::::4                                       b::::::b                                                     //
//         4:::::::::4                                       b::::::b                                                     //
//        4::::44::::4                                        b:::::b                                                     //
//       4::::4 4::::4      ccccccccccccccccuuuuuu    uuuuuu  b:::::bbbbbbbbb        eeeeeeeeeeee        ssssssssss       //
//      4::::4  4::::4    cc:::::::::::::::cu::::u    u::::u  b::::::::::::::bb    ee::::::::::::ee    ss::::::::::s      //
//     4::::4   4::::4   c:::::::::::::::::cu::::u    u::::u  b::::::::::::::::b  e::::::eeeee:::::eess:::::::::::::s     //
//    4::::444444::::444c:::::::cccccc:::::cu::::u    u::::u  b:::::bbbbb:::::::be::::::e     e:::::es::::::ssss:::::s    //
//    4::::::::::::::::4c::::::c     cccccccu::::u    u::::u  b:::::b    b::::::be:::::::eeeee::::::e s:::::s  ssssss     //
//    4444444444:::::444c:::::c             u::::u    u::::u  b:::::b     b:::::be:::::::::::::::::e    s::::::s          //
//              4::::4  c:::::c             u::::u    u::::u  b:::::b     b:::::be::::::eeeeeeeeeee        s::::::s       //
//              4::::4  c::::::c     cccccccu:::::uuuu:::::u  b:::::b     b:::::be:::::::e           ssssss   s:::::s     //
//              4::::4  c:::::::cccccc:::::cu:::::::::::::::uub:::::bbbbbb::::::be::::::::e          s:::::ssss::::::s    //
//            44::::::44 c:::::::::::::::::c u:::::::::::::::ub::::::::::::::::b  e::::::::eeeeeeee  s::::::::::::::s     //
//            4::::::::4  cc:::::::::::::::c  uu::::::::uu:::ub:::::::::::::::b    ee:::::::::::::e   s:::::::::::ss      //
//            4444444444    cccccccccccccccc    uuuuuuuu  uuuubbbbbbbbbbbbbbbb       eeeeeeeeeeeeee    sssssssssss        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FCUBES is ERC721Creator {
    constructor() ERC721Creator("4Cubes", "FCUBES") {}
}