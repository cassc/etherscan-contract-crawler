// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: characterizing the silence
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//           .__                                __               .__       .__                   __  .__                    .__.__                                  //
//      ____ |  |__ _____ ____________    _____/  |_  ___________|__|______|__| ____    ____   _/  |_|  |__   ____     _____|__|  |   ____   ____   ____  ____      //
//    _/ ___\|  |  \\__  \\_  __ \__  \ _/ ___\   __\/ __ \_  __ \  \___   /  |/    \  / ___\  \   __\  |  \_/ __ \   /  ___/  |  | _/ __ \ /    \_/ ___\/ __ \     //
//    \  \___|   Y  \/ __ \|  | \// __ \\  \___|  | \  ___/|  | \/  |/    /|  |   |  \/ /_/  >  |  | |   Y  \  ___/   \___ \|  |  |_\  ___/|   |  \  \__\  ___/     //
//     \___  >___|  (____  /__|  (____  /\___  >__|  \___  >__|  |__/_____ \__|___|  /\___  /   |__| |___|  /\___  > /____  >__|____/\___  >___|  /\___  >___  >    //
//         \/     \/     \/           \/     \/          \/               \/       \//_____/              \/     \/       \/             \/     \/     \/    \/     //
//              ___.                                              _____                      __                                                                     //
//              \_ |__ ___.__.   _________________    ____  _____/ ____\______  ____   _____/  |_                                                                   //
//      ______   | __ <   |  |  /  ___/\____ \__  \ _/ ___\/ __ \   __\\_  __ \/  _ \ /  _ \   __\   ______                                                         //
//     /_____/   | \_\ \___  |  \___ \ |  |_> > __ \\  \__\  ___/|  |   |  | \(  <_> |  <_> )  |    /_____/                                                         //
//               |___  / ____| /____  >|   __(____  /\___  >___  >__|   |__|   \____/ \____/|__|                                                                    //
//                   \/\/           \/ |__|       \/     \/    \/                                                                                                   //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract space is ERC1155Creator {
    constructor() ERC1155Creator("characterizing the silence", "space") {}
}