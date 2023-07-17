// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trapestry
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//             tttt                                                                                                              tttt                                                       //
//          ttt:::t                                                                                                           ttt:::t                                                       //
//          t:::::t                                                                                                           t:::::t                                                       //
//          t:::::t                                                                                                           t:::::t                                                       //
//    ttttttt:::::ttttttt   rrrrr   rrrrrrrrr   aaaaaaaaaaaaa  ppppp   ppppppppp       eeeeeeeeeeee        ssssssssss   ttttttt:::::ttttttt   rrrrr   rrrrrrrrryyyyyyy           yyyyyyy    //
//    t:::::::::::::::::t   r::::rrr:::::::::r  a::::::::::::a p::::ppp:::::::::p    ee::::::::::::ee    ss::::::::::s  t:::::::::::::::::t   r::::rrr:::::::::ry:::::y         y:::::y     //
//    t:::::::::::::::::t   r:::::::::::::::::r aaaaaaaaa:::::ap:::::::::::::::::p  e::::::eeeee:::::eess:::::::::::::s t:::::::::::::::::t   r:::::::::::::::::ry:::::y       y:::::y      //
//    tttttt:::::::tttttt   rr::::::rrrrr::::::r         a::::app::::::ppppp::::::pe::::::e     e:::::es::::::ssss:::::stttttt:::::::tttttt   rr::::::rrrrr::::::ry:::::y     y:::::y       //
//          t:::::t          r:::::r     r:::::r  aaaaaaa:::::a p:::::p     p:::::pe:::::::eeeee::::::e s:::::s  ssssss       t:::::t          r:::::r     r:::::r y:::::y   y:::::y        //
//          t:::::t          r:::::r     rrrrrrraa::::::::::::a p:::::p     p:::::pe:::::::::::::::::e    s::::::s            t:::::t          r:::::r     rrrrrrr  y:::::y y:::::y         //
//          t:::::t          r:::::r           a::::aaaa::::::a p:::::p     p:::::pe::::::eeeeeeeeeee        s::::::s         t:::::t          r:::::r               y:::::y:::::y          //
//          t:::::t    ttttttr:::::r          a::::a    a:::::a p:::::p    p::::::pe:::::::e           ssssss   s:::::s       t:::::t    ttttttr:::::r                y:::::::::y           //
//          t::::::tttt:::::tr:::::r          a::::a    a:::::a p:::::ppppp:::::::pe::::::::e          s:::::ssss::::::s      t::::::tttt:::::tr:::::r                 y:::::::y            //
//          tt::::::::::::::tr:::::r          a:::::aaaa::::::a p::::::::::::::::p  e::::::::eeeeeeee  s::::::::::::::s       tt::::::::::::::tr:::::r                  y:::::y             //
//            tt:::::::::::ttr:::::r           a::::::::::aa:::ap::::::::::::::pp    ee:::::::::::::e   s:::::::::::ss          tt:::::::::::ttr:::::r                 y:::::y              //
//              ttttttttttt  rrrrrrr            aaaaaaaaaa  aaaap::::::pppppppp        eeeeeeeeeeeeee    sssssssssss              ttttttttttt  rrrrrrr                y:::::y               //
//                                                              p:::::p                                                                                              y:::::y                //
//                                                              p:::::p                                                                                             y:::::y                 //
//                                                             p:::::::p                                                                                           y:::::y                  //
//                                                             p:::::::p                                                                                          y:::::y                   //
//                                                             p:::::::p                                                                                         yyyyyyy                    //
//                                                             ppppppppp                                                                                                                    //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Ty is ERC721Creator {
    constructor() ERC721Creator("Trapestry", "Ty") {}
}