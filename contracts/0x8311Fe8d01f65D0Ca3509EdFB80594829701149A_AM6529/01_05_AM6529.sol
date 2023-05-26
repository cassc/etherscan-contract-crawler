// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: seize the memes of reproduction
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0l;;;;;:kNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMKdoooc.......;looodOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKOc.   .,,,,,,,..    ;k0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWWO,..',,,,,,,,,,,,,,,,,...xNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx,''.',,,,,,,,,,,,,,,,,,,''''lXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKdc,..,,,,,,,,,,,,,,,,,,,,,,,,..'co0WMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKkl...,,,,'..................',,,,'..:x0NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX: .',,,,,'.                  .'''',,,. 'OMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX:  ',,,'.           .co,          .',. .OMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX:  ',..      ,ccc:.  .'.   ,ccc:.  ',. .OMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMKxo,..,,.  .,. .l000k,  .,.  .o000k,  ',...cd0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWd. .,,''..'dk:  :dddo' .ok;  .:dddo,..;:::;..lXWWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMd. .,.  ;dxkk:   ....  .dk:.   ....:ddxxxkkxxkO000KWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMd. .,.  :kOOOxollllllllokOxollllllc,...'lkOOOOOOOO00KNMMMMMMMMMMMMM    //
//    MMMMMMMMMMNkl;.....  .;cxOOOOOdc:oOOOOOOOOOOd::l'    ;kOOOOOOOOOO0XMMMMMMMMMMMMM    //
//    MMMMMMMMMMK, .,,.      .lkkOOOo,'lkOkolllloxo,':'    'lokOOOOOOOOOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMK, .,'.      .:odkOOOkkkOOo'.....oOkkd'      .lkkxxkOOOOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMK, .,'.      .;loodkOOOOOOkdoooodkOxdl.       ,:,.'oOOOOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMK, .,'.      .;llllodddddddddddddddolc.       .,. .cOOOOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMK, .,'.      .;lllllllll:;;;;;;;;clllc.       .,. .cOOOOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMXc..'..      .:oollllc::'........:lllc.      ..'..'oOOOOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNXo. .'.    .lkdolll;..,ccccccccllllc.    .'.. :0K0OOO0XMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWd. .,.    .oOkxxolc;;:llllllllll;..   .....lkKWWKOOO0XMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0oc,....  .oOOOOxdl,''''''''''''.   ....,cdXMKdlc::::lokNMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX;  ',. .oOOOOOOc.              ...'',xWWKOc.        '0MMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX;  ',. .oOOOOOOc.      ..'''''''..;0NWM0, .',,,,,'. '0MMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX:  ',. .oOOOOOOc.    ...       .lOKWMMM0' .,,,,,,,. '0MMMMMMMMMM    //
//    MMMMMMMMMMMMMKo:'..,,. .oOOOOOOc.  ....,clooooodKMMMMMM0' .,,,,,,,. '0MMMMMMMMMM    //
//    MMMMMMMMMMMMMx. .,,,,. .oOOOOOOc. .,'  cKNMMMMMMMMMMMMM0' .,,,,,,,. '0MMMMMMMMMM    //
//    MMMMMMMMMMMMMx. .,,,,. .oOOOOOOc. .,'  cKNMMMMMMMMMMMMM0' .,,,,,,,. '0MMMMMMMMMM    //
//    MMMMMMMMMMMMWx. .,,,,. .oOOOOOOc. .,'  cKXWWWWWWMMMMMWWO' .,,,,,,,. ,0MMMMMMMMMM    //
//    MMMMMMMMMMNOd:..',,,,. .oOOOOOOc. .,'  .ccllllldKMMMWOo:'.',,,,'..;lxNMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract AM6529 is ERC721Creator {
    constructor() ERC721Creator("seize the memes of reproduction", "AM6529") {}
}