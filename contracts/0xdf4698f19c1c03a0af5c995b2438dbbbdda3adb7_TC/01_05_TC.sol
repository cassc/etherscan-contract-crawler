// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toy Cars
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//    TTTTTTTTTTTTTTTTTTTTTTT                                                  CCCCCCCCCCCCC                                                                           //
//    T:::::::::::::::::::::T                                               CCC::::::::::::C                                                                           //
//    T:::::::::::::::::::::T                                             CC:::::::::::::::C                                                                           //
//    T:::::TT:::::::TT:::::T                                            C:::::CCCCCCCC::::C                                                                           //
//    TTTTTT  T:::::T  TTTTTTooooooooooo yyyyyyy           yyyyyyy      C:::::C       CCCCCC  aaaaaaaaaaaaa  rrrrr   rrrrrrrrr       ssssssssss                        //
//            T:::::T      oo:::::::::::ooy:::::y         y:::::y      C:::::C                a::::::::::::a r::::rrr:::::::::r    ss::::::::::s                       //
//            T:::::T     o:::::::::::::::oy:::::y       y:::::y       C:::::C                aaaaaaaaa:::::ar:::::::::::::::::r ss:::::::::::::s                      //
//            T:::::T     o:::::ooooo:::::o y:::::y     y:::::y        C:::::C                         a::::arr::::::rrrrr::::::rs::::::ssss:::::s                     //
//            T:::::T     o::::o     o::::o  y:::::y   y:::::y         C:::::C                  aaaaaaa:::::a r:::::r     r:::::r s:::::s  ssssss                      //
//            T:::::T     o::::o     o::::o   y:::::y y:::::y          C:::::C                aa::::::::::::a r:::::r     rrrrrrr   s::::::s                           //
//            T:::::T     o::::o     o::::o    y:::::y:::::y           C:::::C               a::::aaaa::::::a r:::::r                  s::::::s                        //
//            T:::::T     o::::o     o::::o     y:::::::::y             C:::::C       CCCCCCa::::a    a:::::a r:::::r            ssssss   s:::::s                      //
//          TT:::::::TT   o:::::ooooo:::::o      y:::::::y               C:::::CCCCCCCC::::Ca::::a    a:::::a r:::::r            s:::::ssss::::::s                     //
//          T:::::::::T   o:::::::::::::::o       y:::::y                 CC:::::::::::::::Ca:::::aaaa::::::a r:::::r            s::::::::::::::s                      //
//          T:::::::::T    oo:::::::::::oo       y:::::y                    CCC::::::::::::C a::::::::::aa:::ar:::::r             s:::::::::::ss                       //
//          TTTTTTTTTTT      ooooooooooo        y:::::y                        CCCCCCCCCCCCC  aaaaaaaaaa  aaaarrrrrrr              sssssssssss                         //
//                                             y:::::y                                                                                                                 //
//                                            y:::::y                                                                                                                  //
//                                           y:::::y                                                                                                                   //
//                                          y:::::y                                                                                                                    //
//                                         yyyyyyy                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//    bbbbbbbb                                                                                                                                                         //
//    b::::::b                                       MMMMMMMM               MMMMMMMM                 YYYYYYY       YYYYYYYLLLLLLLLLLL       TTTTTTTTTTTTTTTTTTTTTTT    //
//    b::::::b                                       M:::::::M             M:::::::M                 Y:::::Y       Y:::::YL:::::::::L       T:::::::::::::::::::::T    //
//    b::::::b                                       M::::::::M           M::::::::M                 Y:::::Y       Y:::::YL:::::::::L       T:::::::::::::::::::::T    //
//     b:::::b                                       M:::::::::M         M:::::::::M                 Y::::::Y     Y::::::YLL:::::::LL       T:::::TT:::::::TT:::::T    //
//     b:::::bbbbbbbbb yyyyyyy           yyyyyyy     M::::::::::M       M::::::::::Mrrrrr   rrrrrrrrrYYY:::::Y   Y:::::YYY  L:::::L         TTTTTT  T:::::T  TTTTTT    //
//     b::::::::::::::bby:::::y         y:::::y      M:::::::::::M     M:::::::::::Mr::::rrr:::::::::r  Y:::::Y Y:::::Y     L:::::L                 T:::::T            //
//     b::::::::::::::::by:::::y       y:::::y       M:::::::M::::M   M::::M:::::::Mr:::::::::::::::::r  Y:::::Y:::::Y      L:::::L                 T:::::T            //
//     b:::::bbbbb:::::::by:::::y     y:::::y        M::::::M M::::M M::::M M::::::Mrr::::::rrrrr::::::r  Y:::::::::Y       L:::::L                 T:::::T            //
//     b:::::b    b::::::b y:::::y   y:::::y         M::::::M  M::::M::::M  M::::::M r:::::r     r:::::r   Y:::::::Y        L:::::L                 T:::::T            //
//     b:::::b     b:::::b  y:::::y y:::::y          M::::::M   M:::::::M   M::::::M r:::::r     rrrrrrr    Y:::::Y         L:::::L                 T:::::T            //
//     b:::::b     b:::::b   y:::::y:::::y           M::::::M    M:::::M    M::::::M r:::::r                Y:::::Y         L:::::L                 T:::::T            //
//     b:::::b     b:::::b    y:::::::::y            M::::::M     MMMMM     M::::::M r:::::r                Y:::::Y         L:::::L         LLLLLL  T:::::T            //
//     b:::::bbbbbb::::::b     y:::::::y             M::::::M               M::::::M r:::::r                Y:::::Y       LL:::::::LLLLLLLLL:::::LTT:::::::TT          //
//     b::::::::::::::::b       y:::::y              M::::::M               M::::::M r:::::r             YYYY:::::YYYY    L::::::::::::::::::::::LT:::::::::T          //
//     b:::::::::::::::b       y:::::y               M::::::M               M::::::M r:::::r             Y:::::::::::Y    L::::::::::::::::::::::LT:::::::::T          //
//     bbbbbbbbbbbbbbbb       y:::::y                MMMMMMMM               MMMMMMMM rrrrrrr             YYYYYYYYYYYYY    LLLLLLLLLLLLLLLLLLLLLLLLTTTTTTTTTTT          //
//                           y:::::y                                                                                                                                   //
//                          y:::::y                                                                                                                                    //
//                         y:::::y                                                                                                                                     //
//                        y:::::y                                                                                                                                      //
//                       yyyyyyy                                                                                                                                       //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TC is ERC721Creator {
    constructor() ERC721Creator("Toy Cars", "TC") {}
}