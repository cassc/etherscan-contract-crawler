// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2022 // OTHERspace FM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//       ___   ____ ___  ___         __ __   ____  ________  ____________                                ________  ___    //
//      |__ \ / __ \__ \|__ \      _/_//_/  / __ \/_  __/ / / / ____/ __ \_________  ____ _________     / ____/  |/  /    //
//      __/ // / / /_/ /__/ /    _/_//_/   / / / / / / / /_/ / __/ / /_/ / ___/ __ \/ __ `/ ___/ _ \   / /_  / /|_/ /     //
//     / __// /_/ / __// __/   _/_//_/    / /_/ / / / / __  / /___/ _, _(__  ) /_/ / /_/ / /__/  __/  / __/ / /  / /      //
//    /____/\____/____/____/  /_//_/      \____/ /_/ /_/ /_/_____/_/ |_/____/ .___/\__,_/\___/\___/  /_/   /_/  /_/       //
//                                                                         /_/                                            //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OSFM2022 is ERC721Creator {
    constructor() ERC721Creator("2022 // OTHERspace FM", "OSFM2022") {}
}