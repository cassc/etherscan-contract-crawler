// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vaporwaves.psd
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//                                                                                               .___    //
//    ___  _______  ______   _____________  _  _______ ___  __ ____   ______    ______  ______ __| _/    //
//    \  \/ /\__  \ \____ \ /  _ \_  __ \ \/ \/ /\__  \\  \/ // __ \ /  ___/    \____ \/  ___// __ |     //
//     \   /  / __ \|  |_> >  <_> )  | \/\     /  / __ \\   /\  ___/ \___ \     |  |_> >___ \/ /_/ |     //
//      \_/  (____  /   __/ \____/|__|    \/\_/  (____  /\_/  \___  >____  > /\ |   __/____  >____ |     //
//                \/|__|                              \/          \/     \/  \/ |__|       \/     \/     //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WAVE is ERC1155Creator {
    constructor() ERC1155Creator("Vaporwaves.psd", "WAVE") {}
}