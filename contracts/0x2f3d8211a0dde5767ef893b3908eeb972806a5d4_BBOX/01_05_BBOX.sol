// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BasquiBox
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//    BBBBBBBBBBBBBBBBB                                                                             iiii  BBBBBBBBBBBBBBBBB                                          //
//    B::::::::::::::::B                                                                           i::::i B::::::::::::::::B                                         //
//    B::::::BBBBBB:::::B                                                                           iiii  B::::::BBBBBB:::::B                                        //
//    BB:::::B     B:::::B                                                                                BB:::::B     B:::::B                                       //
//      B::::B     B:::::B  aaaaaaaaaaaaa      ssssssssss      qqqqqqqqq   qqqqquuuuuu    uuuuuu  iiiiiii   B::::B     B:::::B   ooooooooooo xxxxxxx      xxxxxxx    //
//      B::::B     B:::::B  a::::::::::::a   ss::::::::::s    q:::::::::qqq::::qu::::u    u::::u  i:::::i   B::::B     B:::::B oo:::::::::::oox:::::x    x:::::x     //
//      B::::BBBBBB:::::B   aaaaaaaaa:::::ass:::::::::::::s  q:::::::::::::::::qu::::u    u::::u   i::::i   B::::BBBBBB:::::B o:::::::::::::::ox:::::x  x:::::x      //
//      B:::::::::::::BB             a::::as::::::ssss:::::sq::::::qqqqq::::::qqu::::u    u::::u   i::::i   B:::::::::::::BB  o:::::ooooo:::::o x:::::xx:::::x       //
//      B::::BBBBBB:::::B     aaaaaaa:::::a s:::::s  ssssss q:::::q     q:::::q u::::u    u::::u   i::::i   B::::BBBBBB:::::B o::::o     o::::o  x::::::::::x        //
//      B::::B     B:::::B  aa::::::::::::a   s::::::s      q:::::q     q:::::q u::::u    u::::u   i::::i   B::::B     B:::::Bo::::o     o::::o   x::::::::x         //
//      B::::B     B:::::B a::::aaaa::::::a      s::::::s   q:::::q     q:::::q u::::u    u::::u   i::::i   B::::B     B:::::Bo::::o     o::::o   x::::::::x         //
//      B::::B     B:::::Ba::::a    a:::::assssss   s:::::s q::::::q    q:::::q u:::::uuuu:::::u   i::::i   B::::B     B:::::Bo::::o     o::::o  x::::::::::x        //
//    BB:::::BBBBBB::::::Ba::::a    a:::::as:::::ssss::::::sq:::::::qqqqq:::::q u:::::::::::::::uui::::::iBB:::::BBBBBB::::::Bo:::::ooooo:::::o x:::::xx:::::x       //
//    B:::::::::::::::::B a:::::aaaa::::::as::::::::::::::s  q::::::::::::::::q  u:::::::::::::::ui::::::iB:::::::::::::::::B o:::::::::::::::ox:::::x  x:::::x      //
//    B::::::::::::::::B   a::::::::::aa:::as:::::::::::ss    qq::::::::::::::q   uu::::::::uu:::ui::::::iB::::::::::::::::B   oo:::::::::::oox:::::x    x:::::x     //
//    BBBBBBBBBBBBBBBBB     aaaaaaaaaa  aaaa sssssssssss        qqqqqqqq::::::q     uuuuuuuu  uuuuiiiiiiiiBBBBBBBBBBBBBBBBB      ooooooooooo xxxxxxx      xxxxxxx    //
//                                                                      q:::::q                                                                                      //
//                                                                      q:::::q                                                                                      //
//                                                                     q:::::::q                                                                                     //
//                                                                     q:::::::q                                                                                     //
//                                                                     q:::::::q                                                                                     //
//                                                                     qqqqqqqqq                                                                                     //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BBOX is ERC1155Creator {
    constructor() ERC1155Creator("BasquiBox", "BBOX") {}
}