// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Piscis T3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//    @@@       @@@@@@@@  @@@@@@@  @@@   @@@@@@      @@@        @@@@@@    @@@@@@    @@@@@@   @@@@@@@@      @@@@@@   @@@  @@@  @@@@@@@       //
//    @@@       @@@@@@@@  @@@@@@@   @@  @@@@@@@      @@@       @@@@@@@@  @@@@@@@@  @@@@@@@   @@@@@@@@     @@@@@@@@  @@@  @@@  @@@@@@@@      //
//    @@!       @@!         @@!    @!   [email protected]@          @@!       @@!  @@@  @@!  @@@  [email protected]@       @@!          @@!  @@@  @@!  @@@  @@!  @@@      //
//    [email protected]!       [email protected]!         [email protected]!         [email protected]!          [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       [email protected]!          [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]      //
//    @!!       @!!!:!      @!!         [email protected]@!!       @!!       @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected]@!!    @!!!:!       @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected][email protected]!       //
//    !!!       !!!!!:      !!!          [email protected]!!!      !!!       [email protected]!  !!!  [email protected]!  !!!   [email protected]!!!   !!!!!:       [email protected]!  !!!  [email protected]!  !!!  [email protected][email protected]!        //
//    !!:       !!:         !!:              !:!     !!:       !!:  !!!  !!:  !!!       !:!  !!:          !!:  !!!  !!:  !!!  !!: :!!       //
//     :!:      :!:         :!:             !:!       :!:      :!:  !:!  :!:  !:!      !:!   :!:          :!:  !:!  :!:  !:!  :!:  !:!      //
//     :: ::::   :: ::::     ::         :::: ::       :: ::::  ::::: ::  ::::: ::  :::: ::    :: ::::     ::::: ::  ::::: ::  ::   :::      //
//    : :: : :  : :: ::      :          :: : :       : :: : :   : :  :    : :  :   :: : :    : :: ::       : :  :    : :  :    :   : :      //
//                                                                                                                                          //
//                                                                                                                                          //
//    @@@  @@@  @@@@@@@@   @@@@@@   @@@@@@@    @@@@@@                                                                                       //
//    @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@                                                                                       //
//    @@!  @@@  @@!       @@!  @@@  @@!  @@@  [email protected]@                                                                                           //
//    [email protected]!  @[email protected]  [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!                                                                                           //
//    @[email protected][email protected][email protected]!  @!!!:!    @[email protected][email protected][email protected]!  @[email protected]  [email protected]!  [email protected]@!!                                                                                        //
//    [email protected]!!!!  !!!!!:    [email protected]!!!!  [email protected]!  !!!   [email protected]!!!                                                                                       //
//    !!:  !!!  !!:       !!:  !!!  !!:  !!!       !:!                                                                                      //
//    :!:  !:!  :!:       :!:  !:!  :!:  !:!      !:!                                                                                       //
//    ::   :::   :: ::::  ::   :::   :::: ::  :::: ::                                                                                       //
//     :   : :  : :: ::    :   : :  :: :  :   :: : :                                                                                        //
//                                                                                                                                          //
//                                                                                                                                          //
//    @@@@@@@  @@@  @@@@@@@@  @@@@@@@      @@@@@@                                                                                           //
//    @@@@@@@  @@@  @@@@@@@@  @@@@@@@@     @@@@@@@                                                                                          //
//      @@!    @@!  @@!       @@!  @@@         @@@                                                                                          //
//      [email protected]!    [email protected]!  [email protected]!       [email protected]!  @[email protected]         @[email protected]                                                                                          //
//      @!!    [email protected]  @!!!:!    @[email protected][email protected]!      @[email protected][email protected]                                                                                           //
//      !!!    !!!  !!!!!:    [email protected][email protected]!       [email protected][email protected]!                                                                                           //
//      !!:    !!:  !!:       !!: :!!          !!:                                                                                          //
//      :!:    :!:  :!:       :!:  !:!         :!:                                                                                          //
//       ::     ::   :: ::::  ::   :::     :: ::::                                                                                          //
//       :     :    : :: ::    :   : :      : : :                                                                                           //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PLLOH3 is ERC1155Creator {
    constructor() ERC1155Creator("Piscis T3", "PLLOH3") {}
}