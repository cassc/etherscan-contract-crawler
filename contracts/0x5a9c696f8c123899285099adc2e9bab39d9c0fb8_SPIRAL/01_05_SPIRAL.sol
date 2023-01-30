// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spirals Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//     @@@@@@   @@@@@@@   @@@  @@@@@@@    @@@@@@   @@@        @@@@@@       //
//    @@@@@@@   @@@@@@@@  @@@  @@@@@@@@  @@@@@@@@  @@@       @@@@@@@       //
//    [email protected]@       @@!  @@@  @@!  @@!  @@@  @@!  @@@  @@!       [email protected]@           //
//    [email protected]!       [email protected]!  @[email protected]  [email protected]!  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       [email protected]!           //
//    [email protected]@!!    @[email protected]@[email protected]!   [email protected]  @[email protected][email protected]!   @[email protected][email protected][email protected]!  @!!       [email protected]@!!        //
//     [email protected]!!!   [email protected]!!!    !!!  [email protected][email protected]!    [email protected]!!!!  !!!        [email protected]!!!       //
//         !:!  !!:       !!:  !!: :!!   !!:  !!!  !!:            !:!      //
//        !:!   :!:       :!:  :!:  !:!  :!:  !:!   :!:          !:!       //
//    :::: ::    ::        ::  ::   :::  ::   :::   :: ::::  :::: ::       //
//    :: : :     :        :     :   : :   :   : :  : :: : :  :: : :        //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract SPIRAL is ERC1155Creator {
    constructor() ERC1155Creator("Spirals Editions", "SPIRAL") {}
}