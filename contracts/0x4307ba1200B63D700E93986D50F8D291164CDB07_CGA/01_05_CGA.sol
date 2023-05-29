// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chazz Gold Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//      @@@@@@@ @@@  @@@  @@@@@@  @@@@@@@@ @@@@@@@@       @@@@@@@   @@@@@@  @@@      @@@@@@@        @@@@@@  @@@@@@@  @@@@@@@    //
//     [email protected]@      @@!  @@@ @@!  @@@      @@!      @@!      [email protected]@       @@!  @@@ @@!      @@!  @@@      @@!  @@@ @@!  @@@   @@!      //
//     [email protected]!      @[email protected][email protected][email protected]! @[email protected][email protected][email protected]!    @!!      @!!        [email protected]! @[email protected][email protected] @[email protected]  [email protected]! @!!      @[email protected]  [email protected]!      @[email protected][email protected][email protected]! @[email protected][email protected]!    @!!      //
//     :!!      !!:  !!! !!:  !!!  !!:      !!:          :!!   !!: !!:  !!! !!:      !!:  !!!      !!:  !!! !!: :!!    !!:      //
//      :: :: :  :   : :  :   : : :.::.: : :.::.: :       :: :: :   : :. :  : ::.: : :: :  :        :   : :  :   : :    :       //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CGA is ERC721Creator {
    constructor() ERC721Creator("Chazz Gold Art", "CGA") {}
}