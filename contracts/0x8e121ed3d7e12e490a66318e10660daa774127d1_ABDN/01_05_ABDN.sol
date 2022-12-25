// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SketchArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//     @@@@@@   @@@@@@@   @@@@@@@   @@@  @@@  @@@  @@@  @@@@@@@  @@@@@@@    @@@@@@@@  @@@           //
//    @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@  @@@  @@@@@@@  @@@@@@@@  @@@@@@@@@  @@@           //
//    @@!  @@@  @@!  @@@  @@!  @@@  @@[email protected][email protected]@@  @@!  [email protected]@    @@!    @@!  @@@  [email protected]@        @@!           //
//    [email protected]!  @[email protected]  [email protected]   @[email protected]  [email protected]!  @[email protected]  [email protected][email protected][email protected]!  [email protected]!  @!!    [email protected]!    [email protected]!  @[email protected]  [email protected]!        [email protected]!           //
//    @[email protected][email protected][email protected]!  @[email protected][email protected][email protected]   @[email protected]  [email protected]!  @[email protected] [email protected]!  @[email protected]@[email protected]!     @!!    @[email protected]@[email protected]!   [email protected]! @[email protected][email protected]  @!!           //
//    [email protected]!!!!  [email protected]!!!!  [email protected]!  !!!  [email protected]!  !!!  [email protected]!!!      !!!    [email protected]!!!    !!! [email protected]!!  !!!           //
//    !!:  !!!  !!:  !!!  !!:  !!!  !!:  !!!  !!: :!!     !!:    !!:       :!!   !!:  !!:           //
//    :!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!    :!:    :!:       :!:   !::   :!:          //
//    ::   :::   :: ::::   :::: ::   ::   ::   ::  :::     ::     ::        ::: ::::   :: ::::      //
//     :   : :  :: : ::   :: :  :   ::    :    :   :::     :      :         :: :: :   : :: : :      //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract ABDN is ERC721Creator {
    constructor() ERC721Creator("SketchArt", "ABDN") {}
}