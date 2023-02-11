// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GHOST CLUB Blackbook Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//     @@@@@@@@  @@@  @@@   @@@@@@    @@@@@@   @@@@@@@      @@@@@@@  @@@       @@@  @@@  @@@@@@@       //
//    @@@@@@@@@  @@@  @@@  @@@@@@@@  @@@@@@@   @@@@@@@     @@@@@@@@  @@@       @@@  @@@  @@@@@@@@      //
//    [email protected]@        @@!  @@@  @@!  @@@  [email protected]@         @@!       [email protected]@       @@!       @@!  @@@  @@!  @@@      //
//    [email protected]!        [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!         [email protected]!       [email protected]!       [email protected]!       [email protected]!  @[email protected]  [email protected]   @[email protected]      //
//    [email protected]! @[email protected][email protected]  @[email protected][email protected][email protected]!  @[email protected]  [email protected]!  [email protected]@!!      @!!       [email protected]!       @!!       @[email protected]  [email protected]!  @[email protected][email protected][email protected]       //
//    !!! [email protected]!!  [email protected]!!!!  [email protected]!  !!!   [email protected]!!!     !!!       !!!       !!!       [email protected]!  !!!  [email protected]!!!!      //
//    :!!   !!:  !!:  !!!  !!:  !!!       !:!    !!:       :!!       !!:       !!:  !!!  !!:  !!!      //
//    :!:   !::  :!:  !:!  :!:  !:!      !:!     :!:       :!:        :!:      :!:  !:!  :!:  !:!      //
//     ::: ::::  ::   :::  ::::: ::  :::: ::      ::        ::: :::   :: ::::  ::::: ::   :: ::::      //
//     :: :: :    :   : :   : :  :   :: : :       :         :: :: :  : :: : :   : :  :   :: : ::       //
//                                                                                                     //
//                                    Official Blackbook Collection                                    //
//                                                                                                     //
//     "Empowering creativity worldwide by bringing artists together to collaborate, connect and       //
//                                   share their work with the world."                                 //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GCBC is ERC721Creator {
    constructor() ERC721Creator("GHOST CLUB Blackbook Collection", "GCBC") {}
}