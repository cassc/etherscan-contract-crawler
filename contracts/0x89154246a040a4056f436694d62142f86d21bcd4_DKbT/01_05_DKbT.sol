// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DripKids by Throwdownnfts.eth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    @@@@@@@   @@@@@@@   @@@  @@@@@@@   @@@  @@@  @@@  @@@@@@@    @@@@@@                                                                                                             //
//    @@@@@@@@  @@@@@@@@  @@@  @@@@@@@@  @@@  @@@  @@@  @@@@@@@@  @@@@@@@                                                                                                             //
//    @@!  @@@  @@!  @@@  @@!  @@!  @@@  @@!  [email protected]@  @@!  @@!  @@@  [email protected]@                                                                                                                 //
//    [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected]!  @[email protected]  [email protected]!  @!!  [email protected]!  [email protected]!  @[email protected]  [email protected]!                                                                                                                 //
//    @[email protected]  [email protected]!  @[email protected][email protected]!   [email protected]  @[email protected]@[email protected]!   @[email protected]@[email protected]!   [email protected]  @[email protected]  [email protected]!  [email protected]@!!                                                                                                              //
//    [email protected]!  !!!  [email protected][email protected]!    !!!  [email protected]!!!    [email protected]!!!    !!!  [email protected]!  !!!   [email protected]!!!                                                                                                             //
//    !!:  !!!  !!: :!!   !!:  !!:       !!: :!!   !!:  !!:  !!!       !:!                                                                                                            //
//    :!:  !:!  :!:  !:!  :!:  :!:       :!:  !:!  :!:  :!:  !:!      !:!                                                                                                             //
//     :::: ::  ::   :::   ::   ::        ::  :::   ::   :::: ::  :::: ::                                                                                                             //
//    :: :  :    :   : :  :     :         :   :::  :    :: :  :   :: : :                                                                                                              //
//    @@@@@@@   @@@ @@@                                                                                                                                                               //
//    @@@@@@@@  @@@ @@@                                                                                                                                                               //
//    @@!  @@@  @@! [email protected]@                                                                                                                                                               //
//    [email protected]   @[email protected]  [email protected]! @!!                                                                                                                                                               //
//    @[email protected][email protected][email protected]    [email protected][email protected]!                                                                                                                                                                //
//    [email protected]!!!!    @!!!                                                                                                                                                                //
//    !!:  !!!    !!:                                                                                                                                                                 //
//    :!:  !:!    :!:                                                                                                                                                                 //
//     :: ::::     ::                                                                                                                                                                 //
//    :: : ::      :                                                                                                                                                                  //
//    @@@@@@@  @@@  @@@  @@@@@@@    @@@@@@   @@@  @@@  @@@  @@@@@@@    @@@@@@   @@@  @@@  @@@  @@@  @@@  @@@  @@@  @@@@@@@@  @@@@@@@   @@@@@@       @@@@@@@@  @@@@@@@  @@@  @@@       //
//    @@@@@@@  @@@  @@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@  @@@@ @@@  @@@@ @@@  @@@@@@@@  @@@@@@@  @@@@@@@       @@@@@@@@  @@@@@@@  @@@  @@@       //
//      @@!    @@!  @@@  @@!  @@@  @@!  @@@  @@!  @@!  @@!  @@!  @@@  @@!  @@@  @@!  @@!  @@!  @@[email protected][email protected]@@  @@[email protected][email protected]@@  @@!         @@!    [email protected]@           @@!         @@!    @@!  @@@       //
//      [email protected]!    [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected]!  [email protected]!  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected]!  [email protected]!  [email protected][email protected][email protected]!  [email protected][email protected][email protected]!  [email protected]!         [email protected]!    [email protected]!           [email protected]!         [email protected]!    [email protected]!  @[email protected]       //
//      @!!    @[email protected][email protected][email protected]!  @[email protected][email protected]!   @[email protected]  [email protected]!  @!!  [email protected]  @[email protected]  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @!!  [email protected]  @[email protected]  @[email protected] [email protected]!  @[email protected] [email protected]!  @!!!:!      @!!    [email protected]@!!        @!!!:!      @!!    @[email protected][email protected][email protected]!       //
//      !!!    [email protected]!!!!  [email protected][email protected]!    [email protected]!  !!!  [email protected]!  !!!  [email protected]!  [email protected]!  !!!  [email protected]!  !!!  [email protected]!  !!!  [email protected]!  [email protected]!  !!!  [email protected]!  !!!  !!!!!:      !!!     [email protected]!!!       !!!!!:      !!!    [email protected]!!!!       //
//      !!:    !!:  !!!  !!: :!!   !!:  !!!  !!:  !!:  !!:  !!:  !!!  !!:  !!!  !!:  !!:  !!:  !!:  !!!  !!:  !!!  !!:         !!:         !:!      !!:         !!:    !!:  !!!       //
//      :!:    :!:  !:!  :!:  !:!  :!:  !:!  :!:  :!:  :!:  :!:  !:!  :!:  !:!  :!:  :!:  :!:  :!:  !:!  :!:  !:!  :!:         :!:        !:!  :!:  :!:         :!:    :!:  !:!       //
//       ::    ::   :::  ::   :::  ::::: ::   :::: :: :::    :::: ::  ::::: ::   :::: :: :::    ::   ::   ::   ::   ::          ::    :::: ::  :::   :: ::::     ::    ::   :::       //
//       :      :   : :   :   : :   : :  :     :: :  : :    :: :  :    : :  :     :: :  : :    ::    :   ::    :    :           :     :: : :   :::  : :: ::      :      :   : :       //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DKbT is ERC721Creator {
    constructor() ERC721Creator("DripKids by Throwdownnfts.eth", "DKbT") {}
}