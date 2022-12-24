// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GameTune
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//     .';::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;'.     //
//    'lOK0OkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxc'    //
//    lKKxooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0kol:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;clooo:    //
//    l0kc'..........................................................................................;loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:,okxc......................................................................................,loo:    //
//    l0k::kKKd'.....................................................................................,loo:    //
//    l0k:.';;.......................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:...........................................................................................,loo:    //
//    l0k:......................................... . ...............................................,loo:    //
//    l0k:.................  ..  .. ..   .  ..  ..     ..  ..  ...  .   .    ..  ...  ...............,loo:    //
//    l0k:.................  .              .          ..          ..     .     ..     ..............,loo:    //
//    l0kl;..............   ..              .          ..       .   .     .      .     .............':ooo:    //
//    l0kolc,.....................  ..............................................................':loooo:    //
//    l0koooocc;,''.........................................................................'',;:cloooooo:    //
//    l0kooooooooollcccc:::;;,,''''..........................................''',,,;::::ccclllooooooooooo:    //
//    l0koooooooooooooooooooooolllllccc:::::;,,,,,,,,,,,,,,,,,,,,,;;::::ccccllllooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooollllc::looooooooooooooooooooooooooooooooooooooooooooooooooooooollllc:;;:looooooooo:    //
//    l0kooooooooooooooc:xOo;':ooooooooooooooooooooooooooooooooooooooooooooooooooooolloxxoc;,,,,:looooooo:    //
//    l0kooooooooooooooc:ol;,';ooooooooooooooooooooooooooooooooooooooooolccc:::coooo:cxd;''''',,';ooooooo:    //
//    l0koooooooolccc:c;,,;,,',:::ccoooooooooooooooooooooooooooooooooollodoc;'',;coo:;c;..''',,,';loooooo:    //
//    l0koooooool:oxoc;,,,,,,,''';c::loooooooooooooooooooooooooooooooccdko:;,',,,,:l:'','.''',,,';loooooo:    //
//    l0koooooooc;odc;;,,,'''',,,;;',loooooooooooooooooooooooooooooooc;lc,,,'.',,',llc;,'..''',,:looooooo:    //
//    l0koooooool:;,,,,,','',,',,,,;cloooooooooooooooooooooooooooooooc,,;,,,'.',,',loolc;;;;;;:looooooooo:    //
//    l0kooooooooolllll:'',,,';llllloooooooooooooooooooooooooooooooool:,,,'''',,,,:looooooooooooooooooooo:    //
//    l0kooooooooooooooc;::,,';ooooooooooooooooooooooooooooooooooooooooc;,,'',,,:looooooooooooooooooooooo:    //
//    l0koooooooooooooolcc;'',coooooooooooooooooooooooooooooooooooooooooolccccclooooooooooooooooooooooooo:    //
//    l0kooooooooooooooolcccclooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooooodddddddooooooooodddddddooooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooodxxdddddollooooodxxxddddollooooooooooooooooooooooooooooooooooooo:    //
//    l0koooooooooooooooooooooooooooooooodo:,,,,,,,;:looodo:,,,,,,;;:looooooooooooooooooooooolclclooooooo:    //
//    l0kooooooooooooooooooooooooooooooooc:,,,,,,,,';coolc;,,,,,,,,,;looooooooooooooooooooolcc:c:cclooooo:    //
//    l0koooooooooooooooooooooooooooooooool:;,;,,,;:loooool:;,,;;,;cloooooooooooooooooooollc:::c:c:cllooo:    //
//    l0kooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooc:c:c:c:c:c:cooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolcc:ccc:c:cllooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolccccccclooooo:    //
//    l0koooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolclclooooooo:    //
//    lOxdooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:    //
//    .;codoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolc;'.    //
//       ..',;::clllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc::;,..        //
//               ..............................................................................               //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMTN is ERC721Creator {
    constructor() ERC721Creator("GameTune", "GMTN") {}
}