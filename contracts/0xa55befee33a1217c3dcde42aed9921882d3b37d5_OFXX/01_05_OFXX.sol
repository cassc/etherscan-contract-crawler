// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ofoid Sacrifice [Open Edition]
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    >>......................................................................................    //
//    ........................................................................................    //
//    .....................................................................,,.................    //
//    [email protected]@OFOID:[email protected]@[email protected]@@@/................    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@*[email protected]@@@///................    //
//    [email protected]@@@@@@@@///////////////////&@@@@@@@@[email protected]@@@/////................    //
//    [email protected]@@@@@@@&/////////////////////////#@@@@@@@@///////................    //
//    ...................,@@@@@@@@&/////////////////////////////@@@@@@@@@///..................    //
//    .................,@@@@@@@@@/////////.............../////*@@@@@@@@@@@@...................    //
//    [email protected]@@@@@@@@@//////.....................,*@@@&//@@@@@@@@@@.................    //
//    [email protected]@@@@@@@@@&///......................,@@@&/////@@@@@@@@@@@................    //
//    [email protected]@@@@@@@@@@///.....................,@@@@////////@@@@@@@@@@@...............    //
//    [email protected]@@@@@@@@@@@//....................,@@@&///////.//&@@@@@@@@@@@..............    //
//    ............&@@@@@@@@@@@//...................,@@@&///////....//@@@@@@@@@@@&.............    //
//    [email protected]@@@@@@@@@@@/,.................,@@@&///////......,/@@@@@@@@@@@@.............    //
//    [email protected]@@@@@@@@@@@/................,@@@@///////........./@@@@@@@@@@@@.............    //
//    [email protected]@@@@@@@@@@@/..............,@@@&///////.........../@@@@@@@@@@@@.............    //
//    [email protected]@@@@@@@@@@@/............,@@@&///////............./@@@@@@@@@@@&.............    //
//    ............*@@@@@@@@@@@/..........,@@@&///////.............../@@@@@@@@@@@&.............    //
//    ............/@@@@@@@@@@@@........,@@@&///////................./@@@@@@@@@@@*.............    //
//    ............//@@@@@@@@@@@......*@@@&///////.................../@@@@@@@@@@*/.............    //
//    ............///@@@@@@@@@@@..,*@@@&///////....................,@@@@@@@@@@///.............    //
//    ............'///@@@@@@@@@@,@@@&////////[email protected]@@@@@@@@@///,.............    //
//    .............'////@@@@@@@@@@&////////......................,@@@@@@@@@/////..............    //
//    ..............'/////@@@@@@@@@//////[email protected]@@@@@@@@//////...............    //
//    ................////@@@@@@@@@@@//....................../@@@@@@@@&//////,................    //
//    ................./@@@@////@@@@@@@@@/.............../@@@@@@@@@&////////..................    //
//    .............../@@@@///////////@@@@@@@@@@@@@@@@@@@@@@@@@&///////////....................    //
//    ............./@@@@///////////////////@@SMBL::[email protected]@////////////////.....................    //
//    .............////////////'/////////////////////////////////////.........................    //
//    ............./////////......'//////////////////////////////.............................    //
//    .............///////.............../////////////////....................................    //
//    ............./////......................................................................    //
//    ........................................................................................    //
//    ........................................................................................    //
//    ......................................................................................<<    //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract OFXX is ERC1155Creator {
    constructor() ERC1155Creator("ofoid Sacrifice [Open Edition]", "OFXX") {}
}