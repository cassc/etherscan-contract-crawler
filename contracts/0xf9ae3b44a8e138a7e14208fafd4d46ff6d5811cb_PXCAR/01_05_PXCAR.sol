// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Cars
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//    PPPPPPPPPPPPPPPPP     iiii                                      lllllll              CCCCCCCCCCCCC                                                                                                //
//    P::::::::::::::::P   i::::i                                     l:::::l           CCC::::::::::::C                                                                                                //
//    P::::::PPPPPP:::::P   iiii                                      l:::::l         CC:::::::::::::::C                                                                                                //
//    PP:::::P     P:::::P                                            l:::::l        C:::::CCCCCCCC::::C                                                                                                //
//      P::::P     P:::::Piiiiiii xxxxxxx      xxxxxxx eeeeeeeeeeee    l::::l       C:::::C       CCCCCC  aaaaaaaaaaaaa  rrrrr   rrrrrrrrr       ssssssssss                                             //
//      P::::P     P:::::Pi:::::i  x:::::x    x:::::xee::::::::::::ee  l::::l      C:::::C                a::::::::::::a r::::rrr:::::::::r    ss::::::::::s                                            //
//      P::::PPPPPP:::::P  i::::i   x:::::x  x:::::xe::::::eeeee:::::eel::::l      C:::::C                aaaaaaaaa:::::ar:::::::::::::::::r ss:::::::::::::s                                           //
//      P:::::::::::::PP   i::::i    x:::::xx:::::xe::::::e     e:::::el::::l      C:::::C                         a::::arr::::::rrrrr::::::rs::::::ssss:::::s                                          //
//      P::::PPPPPPPPP     i::::i     x::::::::::x e:::::::eeeee::::::el::::l      C:::::C                  aaaaaaa:::::a r:::::r     r:::::r s:::::s  ssssss                                           //
//      P::::P             i::::i      x::::::::x  e:::::::::::::::::e l::::l      C:::::C                aa::::::::::::a r:::::r     rrrrrrr   s::::::s                                                //
//      P::::P             i::::i      x::::::::x  e::::::eeeeeeeeeee  l::::l      C:::::C               a::::aaaa::::::a r:::::r                  s::::::s                                             //
//      P::::P             i::::i     x::::::::::x e:::::::e           l::::l       C:::::C       CCCCCCa::::a    a:::::a r:::::r            ssssss   s:::::s                                           //
//    PP::::::PP          i::::::i   x:::::xx:::::xe::::::::e         l::::::l       C:::::CCCCCCCC::::Ca::::a    a:::::a r:::::r            s:::::ssss::::::s                                          //
//    P::::::::P          i::::::i  x:::::x  x:::::xe::::::::eeeeeeee l::::::l        CC:::::::::::::::Ca:::::aaaa::::::a r:::::r            s::::::::::::::s                                           //
//    P::::::::P          i::::::i x:::::x    x:::::xee:::::::::::::e l::::::l          CCC::::::::::::C a::::::::::aa:::ar:::::r             s:::::::::::ss                                            //
//    PPPPPPPPPP          iiiiiiiixxxxxxx      xxxxxxx eeeeeeeeeeeeee llllllll             CCCCCCCCCCCCC  aaaaaaaaaa  aaaarrrrrrr              sssssssssss                                              //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//    "Legend has it that death sought to move quickly through the deserts and canyons of our fallen world.                                                                                             //
//    It then used the elements and materials to form the ultimate weapon..."                                                                                                                           //
//                                                                                                                                                                                                      //
//    PixelCars is a collection of 9,999 strange pixels cars.                                                                                                                                           //
//    Each pixel car is your entry ticket into the Fury Road ecosystem.In our dead world some people heard some rumours about different rarities and materials from the cars…                           //
//    Some secrets will be reveal soon !                                                                                                                                                                //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PXCAR is ERC1155Creator {
    constructor() ERC1155Creator("Pixel Cars", "PXCAR") {}
}