// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ballet Ambitions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ...:0NNNNWWNNWWWWNWWNXXXNWWWWWWWWNNNWXd':l,..'.       //
//       ..:0XXNNNNNNWWWWWWWWWWNWWMWWWWWWWWWWXd':o'..'.     //
//      ...;0XXXXNNNWWWWMMMMMMMMMMMWWMWWMMWWWNx,:c. .'.     //
//     ....'xXXXNNNWWWWMMMMMMMMMMMMMWWMMMMMWMWk;,,. .,.     //
//     .....oXNNNNNWWWWWWMMMMMWWWWWWWWWMMMMWMW0:',. .;.     //
//    ......dWWNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMW0:,;. .:'     //
//    .....'xWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,':' .:,     //
//    .....,kWMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMW0,.c, .:,     //
//    ....',kWWMMMMMMMMMMMMMMMMMMMMMWKOXMMMMMMK;'l; .c;.    //
//     ...';kWWWWWMMMMMMMMMMMMMMMMMW0kXWMMMMMMX:'l: .c:.    //
//      .'':0WWWWWWMMMMMMMMMMMMMMMMXkKMMMMMMMMXc'lc..cc.    //
//      .',lKMMMMMMMMMMMMMMMMMMMMMWOkNMMMMMMMMNl'll..ll.    //
//      ..'oKMMMMMMMMMMMMNKKXNWMMMXx0MMMMMMMMMNo'lo..cl.    //
//      .'.cKMMMMMMMMMMMNx::lxXMMWkxXMMMMMMMMMNd'co..:l'    //
//    . .'.,OWMMMWWWMWXK0xc::o0WNklOWMMMMMWWWWNd':o..:l'    //
//      ....dWMMMWWMMK0XNN0ko:looccOWMMMMMWWWWNd.:o. :l'    //
//      ....oKXXNNNWNkOX0xoc,',,,,,lKMMMWWWNNWXd.,o' ,c'    //
//      ....;looodkXKlcodk00l'...'.'xWMMWWWWNNXd.'l' ':'    //
//      ....;dxxdddk000XNNNNOxc.....lNWWWWWNNNXo..:. .,'    //
//      ....,oxxddddONNNNNNXOko;,'..:KNNNNNNNNXo..,. .'.    //
//      ....:odddoodONNKOOkxdolcc:;,:OXXXXNNXXKo..'.  ..    //
//      .  .;oddooodOOdlccccclllllc::cd0XXXXXXKo....  ..    //
//      .  .,cloooooO0Oxolc::cllc::::::cx0xd0XKo. ..  ..    //
//      .  .,cllloooOXXXXKOxoc;,,;;;;:;;;llckX0c. ..  ..    //
//      .  .;lllllloxkKXXXXXkl' ...;cc:c::,;OXOc. ..        //
//      .  ..''''',,,,coooooc:'.  .;lc:ccd::0XXd. ..        //
//                    ..''''...   .;:,,,.,,':col.           //
//      ..            ....'''..  ..;;,,,.     .;.           //
//      .. .           ....'..   ..''.....    .'.           //
//    ..,'... .........''',,,.....';::ccc:,';:;,....        //
//    ..''';:ccloddxxxxxxkkkd'.:l;;kOOkkxdolllc:;;,'....    //
//    ..',;clloodxxxxxxxkkkx;.,oxc.oOOOkkxxddooc:;,,'...    //
//    ..',;:ccooddxxxxxxkkOko.,od;.;xkkkkxxdoolc:;,'....    //
//    .'',,;;:clloooodddxkOkd,,lo;.:xxxxxxddolcc:;,'....    //
//    ..'',;::::ccloodddxxxdl,':c;':loxdddolll::;;,'....    //
//    ..'',;;;:cloooooodddddoc:;;;;:cloolloolccc:;;,,'..    //
//    .'',;;:cclooddoooolooodxdolllllcllc:;:;;,,,'......    //
//    .'''''''',;;;;;;;cllloxxdocccc::cllc;;;;'.'.......    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract BALLET is ERC1155Creator {
    constructor() ERC1155Creator("Ballet Ambitions", "BALLET") {}
}