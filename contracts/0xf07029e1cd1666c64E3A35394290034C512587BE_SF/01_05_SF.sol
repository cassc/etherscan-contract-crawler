// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: shapes + faces
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//                    hhhhhhh                                                                                                                         ffffffffffffffff                                                                              //
//                    h:::::h                                                                                                                        f::::::::::::::::f                                                                             //
//                    h:::::h                                                                                                                       f::::::::::::::::::f                                                                            //
//                    h:::::h                                                                                                   +++++++             f::::::fffffff:::::f                                                                            //
//        ssssssssss   h::::h hhhhh         aaaaaaaaaaaaa  ppppp   ppppppppp       eeeeeeeeeeee        ssssssssss               +:::::+             f:::::f       ffffffaaaaaaaaaaaaa      cccccccccccccccc    eeeeeeeeeeee        ssssssssss       //
//      ss::::::::::s  h::::hh:::::hhh      a::::::::::::a p::::ppp:::::::::p    ee::::::::::::ee    ss::::::::::s              +:::::+             f:::::f             a::::::::::::a   cc:::::::::::::::c  ee::::::::::::ee    ss::::::::::s      //
//    ss:::::::::::::s h::::::::::::::hh    aaaaaaaaa:::::ap:::::::::::::::::p  e::::::eeeee:::::eess:::::::::::::s       +++++++:::::+++++++      f:::::::ffffff       aaaaaaaaa:::::a c:::::::::::::::::c e::::::eeeee:::::eess:::::::::::::s     //
//    s::::::ssss:::::sh:::::::hhh::::::h            a::::app::::::ppppp::::::pe::::::e     e:::::es::::::ssss:::::s      +:::::::::::::::::+      f::::::::::::f                a::::ac:::::::cccccc:::::ce::::::e     e:::::es::::::ssss:::::s    //
//     s:::::s  ssssss h::::::h   h::::::h    aaaaaaa:::::a p:::::p     p:::::pe:::::::eeeee::::::e s:::::s  ssssss       +:::::::::::::::::+      f::::::::::::f         aaaaaaa:::::ac::::::c     ccccccce:::::::eeeee::::::e s:::::s  ssssss     //
//       s::::::s      h:::::h     h:::::h  aa::::::::::::a p:::::p     p:::::pe:::::::::::::::::e    s::::::s            +++++++:::::+++++++      f:::::::ffffff       aa::::::::::::ac:::::c             e:::::::::::::::::e    s::::::s          //
//          s::::::s   h:::::h     h:::::h a::::aaaa::::::a p:::::p     p:::::pe::::::eeeeeeeeeee        s::::::s               +:::::+             f:::::f            a::::aaaa::::::ac:::::c             e::::::eeeeeeeeeee        s::::::s       //
//    ssssss   s:::::s h:::::h     h:::::ha::::a    a:::::a p:::::p    p::::::pe:::::::e           ssssss   s:::::s             +:::::+             f:::::f           a::::a    a:::::ac::::::c     ccccccce:::::::e           ssssss   s:::::s     //
//    s:::::ssss::::::sh:::::h     h:::::ha::::a    a:::::a p:::::ppppp:::::::pe::::::::e          s:::::ssss::::::s            +++++++            f:::::::f          a::::a    a:::::ac:::::::cccccc:::::ce::::::::e          s:::::ssss::::::s    //
//    s::::::::::::::s h:::::h     h:::::ha:::::aaaa::::::a p::::::::::::::::p  e::::::::eeeeeeee  s::::::::::::::s                                f:::::::f          a:::::aaaa::::::a c:::::::::::::::::c e::::::::eeeeeeee  s::::::::::::::s     //
//     s:::::::::::ss  h:::::h     h:::::h a::::::::::aa:::ap::::::::::::::pp    ee:::::::::::::e   s:::::::::::ss                                 f:::::::f           a::::::::::aa:::a cc:::::::::::::::c  ee:::::::::::::e   s:::::::::::ss      //
//      sssssssssss    hhhhhhh     hhhhhhh  aaaaaaaaaa  aaaap::::::pppppppp        eeeeeeeeeeeeee    sssssssssss                                   fffffffff            aaaaaaaaaa  aaaa   cccccccccccccccc    eeeeeeeeeeeeee    sssssssssss        //
//                                                          p:::::p                                                                                                                                                                                 //
//                                                          p:::::p                                                                                                                                                                                 //
//                                                         p:::::::p                                                                                                                                                                                //
//                                                         p:::::::p                                                                                                                                                                                //
//                                                         p:::::::p                                                                                                                                                                                //
//                                                         ppppppppp                                                                                                                                                                                //
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SF is ERC721Creator {
    constructor() ERC721Creator("shapes + faces", "SF") {}
}