// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VANDALS UNION SUPPLY WAREHOUSE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//    @@@  @@@   @@@@@@   @@@  @@@  @@@@@@@    @@@@@@   @@@        @@@@@@      @@@  @@@  @@@  @@@  @@@   @@@@@@   @@@  @@@                                             //
//    @@@  @@@  @@@@@@@@  @@@@ @@@  @@@@@@@@  @@@@@@@@  @@@       @@@@@@@      @@@  @@@  @@@@ @@@  @@@  @@@@@@@@  @@@@ @@@                                             //
//    @@!  @@@  @@!  @@@  @@[email protected][email protected]@@  @@!  @@@  @@!  @@@  @@!       [email protected]@          @@!  @@@  @@[email protected][email protected]@@  @@!  @@!  @@@  @@[email protected][email protected]@@                                             //
//    [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected][email protected][email protected]!  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       [email protected]!          [email protected]!  @[email protected]  [email protected][email protected][email protected]!  [email protected]!  [email protected]!  @[email protected]  [email protected][email protected][email protected]!                                             //
//    @[email protected]  [email protected]!  @[email protected][email protected][email protected]!  @[email protected] [email protected]!  @[email protected]  [email protected]!  @[email protected][email protected][email protected]!  @!!       [email protected]@!!       @[email protected]  [email protected]!  @[email protected] [email protected]!  [email protected]  @[email protected]  [email protected]!  @[email protected] [email protected]!                                             //
//    [email protected]!  !!!  [email protected]!!!!  [email protected]!  !!!  [email protected]!  !!!  [email protected]!!!!  !!!        [email protected]!!!      [email protected]!  !!!  [email protected]!  !!!  !!!  [email protected]!  !!!  [email protected]!  !!!                                             //
//    :!:  !!:  !!:  !!!  !!:  !!!  !!:  !!!  !!:  !!!  !!:            !:!     !!:  !!!  !!:  !!!  !!:  !!:  !!!  !!:  !!!                                             //
//     ::!!:!   :!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!   :!:          !:!      :!:  !:!  :!:  !:!  :!:  :!:  !:!  :!:  !:!                                             //
//      ::::    ::   :::   ::   ::   :::: ::  ::   :::   :: ::::  :::: ::      ::::: ::   ::   ::   ::  ::::: ::   ::   ::                                             //
//       :       :   : :  ::    :   :: :  :    :   : :  : :: : :  :: : :        : :  :   ::    :   :     : :  :   ::    :                                              //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//     @@@@@@   @@@  @@@  @@@@@@@   @@@@@@@   @@@       @@@ @@@     @@@  @@@  @@@   @@@@@@   @@@@@@@   @@@@@@@@  @@@  @@@   @@@@@@   @@@  @@@   @@@@@@   @@@@@@@@      //
//    @@@@@@@   @@@  @@@  @@@@@@@@  @@@@@@@@  @@@       @@@ @@@     @@@  @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@@@@@@  @@@  @@@  @@@@@@@   @@@@@@@@      //
//    [email protected]@       @@!  @@@  @@!  @@@  @@!  @@@  @@!       @@! [email protected]@     @@!  @@!  @@!  @@!  @@@  @@!  @@@  @@!       @@!  @@@  @@!  @@@  @@!  @@@  [email protected]@       @@!           //
//    [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       [email protected]! @!!     [email protected]!  [email protected]!  [email protected]!  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       [email protected]!           //
//    [email protected]@!!    @[email protected]  [email protected]!  @[email protected]@[email protected]!   @[email protected]@[email protected]!   @!!        [email protected][email protected]!      @!!  [email protected]  @[email protected]  @[email protected][email protected][email protected]!  @[email protected][email protected]!   @!!!:!    @[email protected][email protected][email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected]@!!    @!!!:!        //
//     [email protected]!!!   [email protected]!  !!!  [email protected]!!!    [email protected]!!!    !!!         @!!!      [email protected]!  !!!  [email protected]!  [email protected]!!!!  [email protected][email protected]!    !!!!!:    [email protected]!!!!  [email protected]!  !!!  [email protected]!  !!!   [email protected]!!!   !!!!!:        //
//         !:!  !!:  !!!  !!:       !!:       !!:         !!:       !!:  !!:  !!:  !!:  !!!  !!: :!!   !!:       !!:  !!!  !!:  !!!  !!:  !!!       !:!  !!:           //
//        !:!   :!:  !:!  :!:       :!:        :!:        :!:       :!:  :!:  :!:  :!:  !:!  :!:  !:!  :!:       :!:  !:!  :!:  !:!  :!:  !:!      !:!   :!:           //
//    :::: ::   ::::: ::   ::        ::        :: ::::     ::        :::: :: :::   ::   :::  ::   :::   :: ::::  ::   :::  ::::: ::  ::::: ::  :::: ::    :: ::::      //
//    :: : :     : :  :    :         :        : :: : :     :          :: :  : :     :   : :   :   : :  : :: ::    :   : :   : :  :    : :  :   :: : :    : :: ::       //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
//                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VUSW is ERC1155Creator {
    constructor() ERC1155Creator("VANDALS UNION SUPPLY WAREHOUSE", "VUSW") {}
}