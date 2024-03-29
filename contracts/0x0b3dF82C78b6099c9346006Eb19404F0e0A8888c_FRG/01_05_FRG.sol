// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Treachery of Frogs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ...........................',,'''..........'',,',,'''''.........'''''''''''''''','..................    //
//    .........................:0XXXXXKc. ......lXNNXNNXXXXXX0Od:....cXXXNNXXNNNNXXNNXNKc.. ..............    //
//    ........................'OMMMMMMM0, ......dWMMMMMMMMMMMMMMWKl..lWMMMMMMMMMMMMMMMMNl.................    //
//    ........................dWMMMMMMMWx. .....dWMMMMMWWWWMMMMMMMWx.lWMMMMMMMMMMMMMMMMNl.................    //
//    .......................:XMMMMMMMMMXc......dMMMMMMKxl:lOWMMMMMNl'::ccckWMMMMMOcccc:'.................    //
//    ..................... 'OMMMMMMMMMMM0, ....dMMMMMMk:.  ,KMMMMMWo.  .. lWMMMMMd.......................    //
//    ......................dWMMMMNKNMMMMWd. ...dMMMMMM0dc;ckNMMMMMNc......lNMMMMMd.......................    //
//    .....................:XMMMMMk;xMMMMMXc....dWMMMMMWWWWWMMMMMMWx.......lNMMMMMd.......................    //
//    ................... 'OMMMMMXl.lXMMMMM0, ..dWMMMMMMMMMMMMMMWKl........lNMMMMMd.......................    //
//    .................. .dWMMMMMWXKXWMMMMMWd. .dMMMMMMWWWMMMMMWO,.........lNMMMMMd.......................    //
//    ...................:XMMMMMMMMMMMMMMMMMXc..dWMMMMM0odKMMMMMNo. .......lNMMMMWd.......................    //
//    ................. 'kMMMMMWWWWWWWWWMMMMMO'.dWMMMMMk:':XMMMMMNd. ......lNMMMMWd.......................    //
//    ..................oWMMMMWO:::::;:kWMMMMWd.dWMMMMMO:..cXMMMMMWx'......lNMMMMMd.......................    //
//    ................ 'okkxxkd,.... ..'dxxkxko':xkkxkkl,. .:xkxxkxx:......;xxkkkk:.......................    //
//    ...........................  . ................ ....  ................  . ..........................    //
//    ........................clllll:.............':lodxxdol:'.............,llllll,.......................    //
//    .......................oNMMMMM0, .........;xKWMMMMMMMMWXk:......... 'OMMMMMMd.......................    //
//    ...................'clONMMMMMM0, ...... .dNMMMMMMMMMMMMMMNd......,co0WMMMMMMx.......................    //
//    ...................dMMMMMMMMMM0, .......oNMMMMMMMMMMMMMMMMWo... .OMMMMMMMMMMd.......................    //
//    ...................dMMMMMMMMMM0, ..... .kMMMMMMMMMMMMMMMMMMO' . 'OMMMMMMMMMMd.......................    //
//    ...................dNXO0WMMMMM0, ..... 'OMMMMMMMMMMMMMMMMMM0, . .kNKOKMMMMMMd.......................    //
//    ...................';'.lNMMMMM0, ..... 'OMMMMMMMMMMMMMMMMMM0, ...';''kMMMMMMd.......................    //
//    .......................cNMMMMM0, ..... 'OMMMMMMMMMMMMMMMMMM0, ..... .kMMMMMMd.......................    //
//    .......................lNMMMMM0,...... 'OMMMMMMMMMMMMMMMMMM0, ..... .xMMMMMMd.......................    //
//    ...................''''oNMMMMMK:.'''.. .kMMMMMMMMMMMMMMMMMMO' ..'''.,OMMMMMMk'''''..................    //
//    .................cKXXXXNWMMMMMWXXXXXo. .lNMMMMMMMMMMMMMMMMWo. .oXXXXXWMMMMMMNXXXXKc.................    //
//    .................lNMMMMMMMMMMMMMMMMMx. ..oNMMMMMMMMMMMMMMNd....xMMMMMMMMMMMMMMMMMNl.................    //
//    .................lNMMMMMMMMMMMMMMMMMx. ...;xKWMMMMMMMMWKx;.....xMMMMMMMMMMMMMMMMMNl.................    //
//    .................'cccllccccccccccccc,........;cooddooc;........,cccccccccccccccccc'.................    //
//    .................. ....         .. ...........      ...............        .....  ..................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//    ....................................................................................................    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FRG is ERC721Creator {
    constructor() ERC721Creator("The Treachery of Frogs", "FRG") {}
}