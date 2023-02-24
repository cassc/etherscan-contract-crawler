// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Piscis T4
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//    @@@       @@@@@@@@  @@@@@@@  @@@   @@@@@@      @@@        @@@@@@    @@@@@@   @@@@@@@@      //
//    @@@       @@@@@@@@  @@@@@@@   @@  @@@@@@@      @@@       @@@@@@@@  @@@@@@@   @@@@@@@@      //
//    @@!       @@!         @@!    @!   [email protected]@          @@!       @@!  @@@  [email protected]@       @@!           //
//    [email protected]!       [email protected]!         [email protected]!         [email protected]!          [email protected]!       [email protected]!  @[email protected]  [email protected]!       [email protected]!           //
//    @!!       @!!!:!      @!!         [email protected]@!!       @!!       @[email protected]  [email protected]!  [email protected]@!!    @!!!:!        //
//    !!!       !!!!!:      !!!          [email protected]!!!      !!!       [email protected]!  !!!   [email protected]!!!   !!!!!:        //
//    !!:       !!:         !!:              !:!     !!:       !!:  !!!       !:!  !!:           //
//     :!:      :!:         :!:             !:!       :!:      :!:  !:!      !:!   :!:           //
//     :: ::::   :: ::::     ::         :::: ::       :: ::::  ::::: ::  :::: ::    :: ::::      //
//    : :: : :  : :: ::      :          :: : :       : :: : :   : :  :   :: : :    : :: ::       //
//                                                                                               //
//                                                                                               //
//     @@@@@@   @@@  @@@  @@@@@@@      @@@  @@@  @@@@@@@@   @@@@@@   @@@@@@@    @@@@@@           //
//    @@@@@@@@  @@@  @@@  @@@@@@@@     @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@           //
//    @@!  @@@  @@!  @@@  @@!  @@@     @@!  @@@  @@!       @@!  @@@  @@!  @@@  [email protected]@               //
//    [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]     [email protected]!  @[email protected]  [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!               //
//    @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected][email protected]!      @[email protected][email protected][email protected]!  @!!!:!    @[email protected][email protected][email protected]!  @[email protected]  [email protected]!  [email protected]@!!            //
//    [email protected]!  !!!  [email protected]!  !!!  [email protected][email protected]!       [email protected]!!!!  !!!!!:    [email protected]!!!!  [email protected]!  !!!   [email protected]!!!           //
//    !!:  !!!  !!:  !!!  !!: :!!      !!:  !!!  !!:       !!:  !!!  !!:  !!!       !:!          //
//    :!:  !:!  :!:  !:!  :!:  !:!     :!:  !:!  :!:       :!:  !:!  :!:  !:!      !:!           //
//    ::::: ::  ::::: ::  ::   :::     ::   :::   :: ::::  ::   :::   :::: ::  :::: ::           //
//     : :  :    : :  :    :   : :      :   : :  : :: ::    :   : :  :: :  :   :: : :            //
//                                                                                               //
//                                                                                               //
//    @@@@@@@  @@@  @@@@@@@@  @@@@@@@           @@@                                              //
//    @@@@@@@  @@@  @@@@@@@@  @@@@@@@@         @@@@                                              //
//      @@!    @@!  @@!       @@!  @@@        @@[email protected]!                                              //
//      [email protected]!    [email protected]!  [email protected]!       [email protected]!  @[email protected]       [email protected][email protected]!                                              //
//      @!!    [email protected]  @!!!:!    @[email protected][email protected]!       @!! @!!                                              //
//      !!!    !!!  !!!!!:    [email protected][email protected]!       !!!  [email protected]!                                              //
//      !!:    !!:  !!:       !!: :!!      :!!:!:!!:                                             //
//      :!:    :!:  :!:       :!:  !:!     !:::!!:::                                             //
//       ::     ::   :: ::::  ::   :::          :::                                              //
//       :     :    : :: ::    :   : :          :::                                              //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract PLLOH4 is ERC1155Creator {
    constructor() ERC1155Creator("Piscis T4", "PLLOH4") {}
}