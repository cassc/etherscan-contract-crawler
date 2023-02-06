// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Close to You
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//            CCCCCCCCCCCCClllllll                                                                     tttt                                YYYYYYY       YYYYYYY                                    //
//         CCC::::::::::::Cl:::::l                                                                  ttt:::t                                Y:::::Y       Y:::::Y                                    //
//       CC:::::::::::::::Cl:::::l                                                                  t:::::t                                Y:::::Y       Y:::::Y                                    //
//      C:::::CCCCCCCC::::Cl:::::l                                                                  t:::::t                                Y::::::Y     Y::::::Y                                    //
//     C:::::C       CCCCCC l::::l    ooooooooooo       ssssssssss       eeeeeeeeeeee         ttttttt:::::ttttttt       ooooooooooo        YYY:::::Y   Y:::::YYYooooooooooo   uuuuuu    uuuuuu      //
//    C:::::C               l::::l  oo:::::::::::oo   ss::::::::::s    ee::::::::::::ee       t:::::::::::::::::t     oo:::::::::::oo         Y:::::Y Y:::::Y oo:::::::::::oo u::::u    u::::u      //
//    C:::::C               l::::l o:::::::::::::::oss:::::::::::::s  e::::::eeeee:::::ee     t:::::::::::::::::t    o:::::::::::::::o         Y:::::Y:::::Y o:::::::::::::::ou::::u    u::::u      //
//    C:::::C               l::::l o:::::ooooo:::::os::::::ssss:::::se::::::e     e:::::e     tttttt:::::::tttttt    o:::::ooooo:::::o          Y:::::::::Y  o:::::ooooo:::::ou::::u    u::::u      //
//    C:::::C               l::::l o::::o     o::::o s:::::s  ssssss e:::::::eeeee::::::e           t:::::t          o::::o     o::::o           Y:::::::Y   o::::o     o::::ou::::u    u::::u      //
//    C:::::C               l::::l o::::o     o::::o   s::::::s      e:::::::::::::::::e            t:::::t          o::::o     o::::o            Y:::::Y    o::::o     o::::ou::::u    u::::u      //
//    C:::::C               l::::l o::::o     o::::o      s::::::s   e::::::eeeeeeeeeee             t:::::t          o::::o     o::::o            Y:::::Y    o::::o     o::::ou::::u    u::::u      //
//     C:::::C       CCCCCC l::::l o::::o     o::::ossssss   s:::::s e:::::::e                      t:::::t    tttttto::::o     o::::o            Y:::::Y    o::::o     o::::ou:::::uuuu:::::u      //
//      C:::::CCCCCCCC::::Cl::::::lo:::::ooooo:::::os:::::ssss::::::se::::::::e                     t::::::tttt:::::to:::::ooooo:::::o            Y:::::Y    o:::::ooooo:::::ou:::::::::::::::uu    //
//       CC:::::::::::::::Cl::::::lo:::::::::::::::os::::::::::::::s  e::::::::eeeeeeee             tt::::::::::::::to:::::::::::::::o         YYYY:::::YYYY o:::::::::::::::o u:::::::::::::::u    //
//         CCC::::::::::::Cl::::::l oo:::::::::::oo  s:::::::::::ss    ee:::::::::::::e               tt:::::::::::tt oo:::::::::::oo          Y:::::::::::Y  oo:::::::::::oo   uu::::::::uu:::u    //
//            CCCCCCCCCCCCCllllllll   ooooooooooo     sssssssssss        eeeeeeeeeeeeee                 ttttttttttt     ooooooooooo            YYYYYYYYYYYYY    ooooooooooo       uuuuuuuu  uuuu    //
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CTYOU is ERC1155Creator {
    constructor() ERC1155Creator("Close to You", "CTYOU") {}
}