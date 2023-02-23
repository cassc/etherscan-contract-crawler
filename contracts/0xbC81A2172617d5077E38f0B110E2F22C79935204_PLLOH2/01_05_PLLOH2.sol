// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Piscis T2
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
//    @@@@@@@  @@@  @@@@@@@@  @@@@@@@       @@@@@@                                                                                          //
//    @@@@@@@  @@@  @@@@@@@@  @@@@@@@@     @@@@@@@@                                                                                         //
//      @@!    @@!  @@!       @@!  @@@          @@@                                                                                         //
//      [email protected]!    [email protected]!  [email protected]!       [email protected]!  @[email protected]         @[email protected]                                                                                          //
//      @!!    [email protected]  @!!!:!    @[email protected][email protected]!         [email protected]                                                                                           //
//      !!!    !!!  !!!!!:    [email protected][email protected]!         !!:                                                                                            //
//      !!:    !!:  !!:       !!: :!!       !:!                                                                                             //
//      :!:    :!:  :!:       :!:  !:!     :!:                                                                                              //
//       ::     ::   :: ::::  ::   :::     :: :::::                                                                                         //
//       :     :    : :: ::    :   : :     :: : :::                                                                                         //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PLLOH2 is ERC1155Creator {
    constructor() ERC1155Creator("Piscis T2", "PLLOH2") {}
}