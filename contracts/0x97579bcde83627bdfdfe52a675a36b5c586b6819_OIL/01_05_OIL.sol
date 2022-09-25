// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Great Gatsby
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//      @@@@@@@   @@@@@@  @@@@@@@  @@@@@@ @@@@@@@  @@@ @@@    //
//     [email protected]@       @@!  @@@   @@!   [email protected]@     @@!  @@@ @@! [email protected]@    //
//     [email protected]! @[email protected][email protected] @[email protected][email protected][email protected]!   @!!    [email protected]@!!  @[email protected][email protected][email protected]   [email protected][email protected]!     //
//     :!!   !!: !!:  !!!   !!:       !:! !!:  !!!   !!:      //
//      :: :: :   :   : :    :    ::.: :  :: : ::    .:       //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract OIL is ERC721Creator {
    constructor() ERC721Creator("The Great Gatsby", "OIL") {}
}