// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtusMichal Rays
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKOkOOOKNNXXXNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMK:.. ...,'...'',;cokKNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMK;       .clccc:;'. .;oONMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWKl'..      '0MMMMMWX0xl,..;xNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNd. .cd, ...  cNMMMMMMMMMNk:..;OWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMK:..;kWX: .:'  .kMMMMMMMMMMMNk, .dNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMK; .cXMMX: .xo.  :XMMMMMMMMMMMMK: .oNNX0kolclxKWMM    //
//    MMMMMMMMMNl. cXMMMX; 'OK,  .xMMMMMMMMMMMWXx. .;,.........dNM    //
//    MMMMMMMMMO. 'OMMMMK; ,KWd.  cNMMMWNKOxoc;'.   .:ox0KXXKo.,0M    //
//    MMMMMMMMWd. ;XMMMMO' ;KMK;  .lxoc:,..   .':;. :XMMMMMMMKokWM    //
//    MMMMMMMMWo. :NMMMMx. 'ooc'       ..,:lok0NW0' cNMMMMMMMMMMMM    //
//    MMMMMMMMMx. ,kOxoc'       .    'okKNMMMMMMMx..dMMMMMMMMMMMMM    //
//    MMMMMMNKk:. ...       .cdkd'   '0MMMMMMMMMK; ,0MMMMMMMMMMMMM    //
//    MMMW0l,.      .:ld:.  :XMMWx.  .lNMMMMMMMNo..dWMMMMMMMMMMMMM    //
//    MMMO' .;lod;. ,OWMd.  :XMMMNc   .kMMMMMMNo..oNMMMMMMMMMMMMMM    //
//    MMWl .dWMMMXl. .dKl   ;XMMMM0'   :XMMMWO:..dNMMMMMMMMMMMMMMM    //
//    MMMO;.:KMMMMNx' .'.   :XMMMMWd'. .xWXk:..;OWMMMMMMMMMMMMMMMM    //
//    MMMMN0OXMMMMMMXd,.    ,OXNWWWKx;  ':'..:kNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKk0k,    .',;;;,'.   .,o0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKc,:.  ,ol::;;;;::,. '0MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXd:;:dXMMMWWWWWWMK; ,0MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWWMMMMMMWKKNWNk' cNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWO:,,'..;0MMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMXkdookXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract ARTUSMR is ERC1155Creator {
    constructor() ERC1155Creator("ArtusMichal Rays", "ARTUSMR") {}
}