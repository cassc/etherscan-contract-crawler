// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Golden Rhythm
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//     @@@@@@ @@@@@@@ @@@@@@@@ @@@@@@@  @@@  @@@ @@@@@@@   @@@@@@  @@@@@@@   @@@@@@      //
//    [email protected]@       @!!   @@!      @@!  @@@ @@!  @@@ @@!  @@@ @@!  @@@ @@!  @@@ @@!  @@@     //
//     [email protected]@!!    @!!   @!!!:!   @[email protected]@[email protected]!  @[email protected][email protected][email protected]! @[email protected][email protected]!  @[email protected][email protected][email protected]! @[email protected]@[email protected]!  @[email protected]  [email protected]!     //
//        !:!   !!:   !!:      !!:      !!:  !!! !!: :!!  !!:  !!! !!:      !!:  !!!     //
//    ::.: :     :    : :: ::   :        :   : :  :   : :  :   : :  :        : :. :      //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract GOLD is ERC721Creator {
    constructor() ERC721Creator("Golden Rhythm", "GOLD") {}
}