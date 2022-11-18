// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Akihabara
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                    bbbbbbbb                                                                     //
//                   AAA               kkkkkkkk             iiii hhhhhhh                              b::::::b                                                                     //
//                  A:::A              k::::::k            i::::ih:::::h                              b::::::b                                                                     //
//                 A:::::A             k::::::k             iiii h:::::h                              b::::::b                                                                     //
//                A:::::::A            k::::::k                  h:::::h                               b:::::b                                                                     //
//               A:::::::::A            k:::::k    kkkkkkkiiiiiii h::::h hhhhh         aaaaaaaaaaaaa   b:::::bbbbbbbbb      aaaaaaaaaaaaa  rrrrr   rrrrrrrrr   aaaaaaaaaaaaa       //
//              A:::::A:::::A           k:::::k   k:::::k i:::::i h::::hh:::::hhh      a::::::::::::a  b::::::::::::::bb    a::::::::::::a r::::rrr:::::::::r  a::::::::::::a      //
//             A:::::A A:::::A          k:::::k  k:::::k   i::::i h::::::::::::::hh    aaaaaaaaa:::::a b::::::::::::::::b   aaaaaaaaa:::::ar:::::::::::::::::r aaaaaaaaa:::::a     //
//            A:::::A   A:::::A         k:::::k k:::::k    i::::i h:::::::hhh::::::h            a::::a b:::::bbbbb:::::::b           a::::arr::::::rrrrr::::::r         a::::a     //
//           A:::::A     A:::::A        k::::::k:::::k     i::::i h::::::h   h::::::h    aaaaaaa:::::a b:::::b    b::::::b    aaaaaaa:::::a r:::::r     r:::::r  aaaaaaa:::::a     //
//          A:::::AAAAAAAAA:::::A       k:::::::::::k      i::::i h:::::h     h:::::h  aa::::::::::::a b:::::b     b:::::b  aa::::::::::::a r:::::r     rrrrrrraa::::::::::::a     //
//         A:::::::::::::::::::::A      k:::::::::::k      i::::i h:::::h     h:::::h a::::aaaa::::::a b:::::b     b:::::b a::::aaaa::::::a r:::::r           a::::aaaa::::::a     //
//        A:::::AAAAAAAAAAAAA:::::A     k::::::k:::::k     i::::i h:::::h     h:::::ha::::a    a:::::a b:::::b     b:::::ba::::a    a:::::a r:::::r          a::::a    a:::::a     //
//       A:::::A             A:::::A   k::::::k k:::::k   i::::::ih:::::h     h:::::ha::::a    a:::::a b:::::bbbbbb::::::ba::::a    a:::::a r:::::r          a::::a    a:::::a     //
//      A:::::A               A:::::A  k::::::k  k:::::k  i::::::ih:::::h     h:::::ha:::::aaaa::::::a b::::::::::::::::b a:::::aaaa::::::a r:::::r          a:::::aaaa::::::a     //
//     A:::::A                 A:::::A k::::::k   k:::::k i::::::ih:::::h     h:::::h a::::::::::aa:::ab:::::::::::::::b   a::::::::::aa:::ar:::::r           a::::::::::aa:::a    //
//    AAAAAAA                   AAAAAAAkkkkkkkk    kkkkkkkiiiiiiiihhhhhhh     hhhhhhh  aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb     aaaaaaaaaa  aaaarrrrrrr            aaaaaaaaaa  aaaa    //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Akh is ERC721Creator {
    constructor() ERC721Creator("Akihabara", "Akh") {}
}