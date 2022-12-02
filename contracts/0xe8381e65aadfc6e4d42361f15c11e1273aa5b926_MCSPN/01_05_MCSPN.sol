// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mac's Pane
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//         @@@@@@@@@@    @@@@@@    @@@@@@@  @@@   @@@@@@          //
//         @@@@@@@@@@@  @@@@@@@@  @@@@@@@@   @@  @@@@@@@          //
//         @@! @@! @@!  @@!  @@@  [email protected]@       @!   [email protected]@              //
//         [email protected]! [email protected]! [email protected]!  [email protected]!  @[email protected]  [email protected]!            [email protected]!              //
//         @!! [email protected] @[email protected]  @[email protected][email protected][email protected]!  [email protected]!            [email protected]@!!           //
//         [email protected]!   ! [email protected]!  [email protected]!!!!  !!!             [email protected]!!!          //
//         !!:     !!:  !!:  !!!  :!!                 !:!         //
//         :!:     :!:  :!:  !:!  :!:                !:!          //
//         :::     ::   ::   :::   ::: :::       :::: ::          //
//          :      :     :   : :   :: :: :       :: : :           //
//                                                                //
//                                                                //
//            @@@@@@@    @@@@@@   @@@  @@@  @@@@@@@@              //
//            @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@@              //
//            @@!  @@@  @@!  @@@  @@[email protected][email protected]@@  @@!                   //
//            [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected][email protected][email protected]!  [email protected]!                   //
//            @[email protected]@[email protected]!   @[email protected][email protected][email protected]!  @[email protected] [email protected]!  @!!!:!                //
//            [email protected]!!!    [email protected]!!!!  [email protected]!  !!!  !!!!!:                //
//            !!:       !!:  !!!  !!:  !!!  !!:                   //
//            :!:       :!:  !:!  :!:  !:!  :!:                   //
//             ::       ::   :::   ::   ::   :: ::::              //
//             :         :   : :  ::    :   : :: ::               //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract MCSPN is ERC1155Creator {
    constructor() ERC1155Creator("Mac's Pane", "MCSPN") {}
}