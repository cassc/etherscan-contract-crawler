// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REBBIT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//    RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEEBBBBBBBBBBBBBBBBB  BBBBBBBBBBBBBBBBB   IIIIIIIIIITTTTTTTTTTTTTTTTTTTTTTT    //
//    R::::::::::::::::R  E::::::::::::::::::::EB::::::::::::::::B B::::::::::::::::B  I::::::::IT:::::::::::::::::::::T    //
//    R::::::RRRRRR:::::R E::::::::::::::::::::EB::::::BBBBBB:::::BB::::::BBBBBB:::::B I::::::::IT:::::::::::::::::::::T    //
//    RR:::::R     R:::::REE::::::EEEEEEEEE::::EBB:::::B     B:::::BB:::::B     B:::::BII::::::IIT:::::TT:::::::TT:::::T    //
//      R::::R     R:::::R  E:::::E       EEEEEE  B::::B     B:::::B B::::B     B:::::B  I::::I  TTTTTT  T:::::T  TTTTTT    //
//      R::::R     R:::::R  E:::::E               B::::B     B:::::B B::::B     B:::::B  I::::I          T:::::T            //
//      R::::RRRRRR:::::R   E::::::EEEEEEEEEE     B::::BBBBBB:::::B  B::::BBBBBB:::::B   I::::I          T:::::T            //
//      R:::::::::::::RR    E:::::::::::::::E     B:::::::::::::BB   B:::::::::::::BB    I::::I          T:::::T            //
//      R::::RRRRRR:::::R   E:::::::::::::::E     B::::BBBBBB:::::B  B::::BBBBBB:::::B   I::::I          T:::::T            //
//      R::::R     R:::::R  E::::::EEEEEEEEEE     B::::B     B:::::B B::::B     B:::::B  I::::I          T:::::T            //
//      R::::R     R:::::R  E:::::E               B::::B     B:::::B B::::B     B:::::B  I::::I          T:::::T            //
//      R::::R     R:::::R  E:::::E       EEEEEE  B::::B     B:::::B B::::B     B:::::B  I::::I          T:::::T            //
//    RR:::::R     R:::::REE::::::EEEEEEEE:::::EBB:::::BBBBBB::::::BB:::::BBBBBB::::::BII::::::II      TT:::::::TT          //
//    R::::::R     R:::::RE::::::::::::::::::::EB:::::::::::::::::BB:::::::::::::::::B I::::::::I      T:::::::::T          //
//    R::::::R     R:::::RE::::::::::::::::::::EB::::::::::::::::B B::::::::::::::::B  I::::::::I      T:::::::::T          //
//    RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEEBBBBBBBBBBBBBBBBB  BBBBBBBBBBBBBBBBB   IIIIIIIIII      TTTTTTTTTTT          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RB is ERC721Creator {
    constructor() ERC721Creator("REBBIT", "RB") {}
}