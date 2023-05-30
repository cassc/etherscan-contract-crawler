// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Totty 1/1's
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//     @@@@@@@  @@@@@@  @@@@@@@ @@@@@@@ @@@ @@@       @@@     @@@  @@@  @@  @@@@@@    //
//       @@!   @@!  @@@   @@!     @@!   @@! [email protected]@       @@@    @@@   @@@ [email protected]  [email protected]@        //
//       @!!   @[email protected]  [email protected]!   @!!     @!!    [email protected][email protected]!        [email protected]!   [email protected]    [email protected]!      [email protected]@!!     //
//       !!:   !!:  !!!   !!:     !!:     !!:         !!!  !!!     !!!         !:!    //
//        :     : :. :     :       :      .:          :   : :      :       ::.: :     //
//                                                                                    //
//                           a r e n ' t  y o u  l u c k y                            //
//                                                                                    //
//                 _    _  _  _  _|_ _ _|  |_      _  _  _ .(_ _ | _|                 //
//                _)|_||_)|_)(_)| |_(-(_|  |_)\/  |||(_|| )|| (_)|(_|                 //
//                     |  |                   /                                       //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract TTYMNFLD is ERC721Creator {
    constructor() ERC721Creator("Totty 1/1's", "TTYMNFLD") {}
}