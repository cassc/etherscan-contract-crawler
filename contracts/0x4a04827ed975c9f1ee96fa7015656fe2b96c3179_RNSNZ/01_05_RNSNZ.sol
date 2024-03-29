// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RENAISSANCE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''......''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''....'''.   ...'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.. ..''.     ..'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..   .''.    ..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.    .''.    ..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...'''''''..    ..'.    ..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''....'''''''''...''''.'''''''''..    ..''.    .'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.. ...'''''''....'''''''''''....     .''..    .'''''''.....'''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..'''''...    .''......  ..''''....''....     .'''.   ...'''....   ..'''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.'''''..      ...       ..'.........'..       ....    ......      ..''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''...''''''''''''''''''''........      .          ....        ..       ....      .         ..'''''''''''''.'''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''.. ....''''....'''............                                        ..                ...''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''....'''''''''''....    ...'............                                                                     ...'''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''...   ..............       .............                                                                         ..'''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''...                                                                                                               ..'''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''..                                                                                                               ..'''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''...                                                                                                                   ..'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''..                                                                                                                      ..''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''...                                                                                                                     ....'''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''....                                                                                                                     ....'''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''..... ...     .......                                                                                                     ..''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''.......''''...                                                                                                    ..''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''.''''''''''''..                                                                                                 ...'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''....                                                                                                     ..'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''.....                                                                                                      ..   .'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''....                                                                                                            ..  ....''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''..                                                                          ....      ..                         ........''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''..                                                                           .,,..     ....                        .''''...'''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''.           .                                                                 ';,'.    ....                  ..    .'.''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''...  .......                                                           .      .,;'..    ..'..                 ...  .'.''..''.'''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''.....''...       ..                                                  ....     .,c:;,.  .',''.                  ......''''''''..'''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''..          ..                                                   ..'..   .;lcc;'..';;;,'..                 .....'.'''..''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''...    ..     ...                                                  ..,''.  .;lclc;;ccc::;,,..                  ..'..'''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''.'......'..     ....                                                 ..',;,. .;lllllllllc::;,'...                 .''.'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''..''''...'''.      ....                                                 ..,,;;,.':ollcclllcc::;,''..          ..     ....'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''..''''''''''''.      ..'.                                               ....',;:c::clcc:clllc:::;,'....        .....    ...'''..''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''..''''''''''''..      ..'.                                               ....',;::cllccccccllc::;;,,'.......    .'''..    ..''..'''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''...'''''''''''''..   .  ..''.                                             .....',;;;::::cclcccc:;:;,,''........   .'''..     .'..''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''..'''''''''''''''......  .''.                                              ....'',,;;;:ccccc:;;;;;,''.........   ..''''..    ..''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''..''''''''''''''..'.......''.                                               ....'',,;;:ccllcc:;;,,''..........   .''''''.    ..''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''..''''''.'''''''..'''''..'''.                                                ...'''',;;::cc:;;,,'..............  .''''''..  ...''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''....''...'''''''..''''''''''..                                              .....'''',,;,,''................... ..'''''''....'.''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''.......''''''...'''''.'''''..                                            ...............      ... ..........  ........''..'''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''........''....''...........                        ....                .......           ...',....  .. ... ......'.''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''..'..........'....     ...                          ....              ......              ..'....    .............''.'''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''..'''''.........'.                            .....''....             .,,,.          ...',,'.    ..   ...  .......'..'''.....'''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''...'''''.........'.                          .',;:cldxdl;...           .;:,.  ..   ...';ldkOOxc.   ..   .......  .....'''......''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''...'''''........'.                           ..';;:clolc;.             .::'. .........';coxkOx:.         ....'.  ....''''''''...'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''...''''''..'....'.                              ...........            .,,.   ..''.    ..',,'..  ..      ....'.  .''.''''''''...'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''...''''''.........           .                          .               ....    ...'....     ......       .  .. ..''....'''''..''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''...'''''''.......'.          .                                          ....  ...  ..,,,,,,''.....           ............'''...''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''..''''''''......'..         .                                          ....   .'''....';:c:;,,'..           ........'...''...'''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''...'''''''.......'.         .                                          ....    .,,,,;'..'',,;;,..        .  ................''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''...''''''''....'...          .                                         .....   ..',;:::::::;,''..       .......''..........'''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''...''''''''....''.          .                                         .'...    .';::::cllllc;,...      ...........'.....'.'''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''...'''''''''....''.         ..                                       .;::;'..   .';;;:cccc:;,'....     ......''........'''.''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''...''''''''.....''.         .                                       .;cc:;'.'.....'',;;,,,''....      .....''....''....'''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''....''''''''........  .                                             .......................         ......'...'''.....'''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''....''''''''..'....''                                              .         ...........         ......''..''''..'...''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''....'''''''......,;''.                                      ..     ........,;,.....             .....''''''...''..'''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''.....''''''.....',,'.                                      ......','...',;;;,,'...             ....'''''''..'''..'''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''....'''''.........                                       .','''.......'',,,'....           ....'''''...''''...'''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''......''........                                       ..............'''''....           ....''''..''''''..''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''.............                                    ....................'....           ...'''''''''.''...''..''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''..'......                               ............',,',,,'.........                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RNSNZ is ERC721Creator {
    constructor() ERC721Creator("RENAISSANCE", "RNSNZ") {}
}